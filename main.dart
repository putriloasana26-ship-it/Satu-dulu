import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'focus_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setTitle('Satu Dulu');
  }
  runApp(const SatuDuluApp());
}

class SatuDuluApp extends StatelessWidget {
  const SatuDuluApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Satu Dulu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF3F7D6B), useMaterial3: true),
        home: const HomePage(),
      );
}

class Blocked {
  Blocked(this.name, this.keywords, {this.on = false});
  final String name;
  final List<String> keywords; // dicocokkan ke nama package / judul jendela
  bool on;
  bool matches(String fg) => keywords.any((k) => fg.toLowerCase().contains(k));
}

enum Stage { setup, focus, report }

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Stage stage = Stage.setup;
  int minutes = 25;
  final apps = [
    Blocked('Instagram', ['instagram'], on: true),
    Blocked('TikTok', ['tiktok', 'musically'], on: true),
    Blocked('YouTube', ['youtube'], on: true),
    Blocked('Game', ['roblox', 'mobilelegends', 'moonton', 'genshin', 'steam', 'minecraft']),
  ];
  final custom = TextEditingController();
  bool permitted = true;

  Timer? _tick;
  int total = 0, remaining = 0, attempts = 0, polls = 0;
  bool inViolation = false, completed = false;
  String warning = '';

  @override
  void initState() {
    super.initState();
    FocusPlatform.hasPermission().then((v) => setState(() => permitted = v));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  // ---- Focus Mode ----
  void start() {
    total = remaining = minutes * 60;
    attempts = 0;
    inViolation = false;
    warning = '';
    setState(() => stage = Stage.focus);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) async {
      remaining--;
      if (++polls % 2 == 0) await _check();
      if (remaining <= 0) return _finish(true);
      if (mounted) setState(() {});
    });
  }

  // ---- Distraction Warning ----
  Future<void> _check() async {
    final fg = await FocusPlatform.foreground();
    final hit = apps.where((a) => a.on && a.matches(fg));
    if (hit.isNotEmpty && !inViolation) {
      inViolation = true;
      attempts++;
      warning = 'Kamu membuka ${hit.first.name}. Satu dulu, kembali fokus!';
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      await FocusPlatform.bringToFront();
    } else if (hit.isEmpty) {
      inViolation = false;
    }
  }

  void _finish(bool done) {
    _tick?.cancel();
    completed = done;
    if (done) {
      // Notifikasi/bunyi penanda sesi selesai
      for (var i = 0; i < 3; i++) {
        Future.delayed(Duration(milliseconds: 700 * i), () => SystemSound.play(SystemSoundType.alert));
      }
    }
    if (mounted) setState(() => stage = Stage.report);
  }

  Future<void> _stopEarly() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hentikan sesi?'),
        content: const Text('Gunakan hanya untuk keperluan darurat. Sesi akan tercatat belum selesai.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Lanjut belajar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hentikan')),
        ],
      ),
    );
    if (ok == true) _finish(false);
  }

  // ---- Focus Report ----
  int get studied => total - remaining.clamp(0, total);
  int get score => ((studied / total) * 100 - attempts * 10).clamp(0, 100).round();
  String get scoreLabel => score >= 80 ? 'Sangat fokus' : score >= 50 ? 'Cukup fokus' : 'Perlu ditingkatkan';
  String fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Satu Dulu'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: switch (stage) {
              Stage.setup => _setup(),
              Stage.focus => _focus(),
              Stage.report => _report(),
            },
          ),
        ),
      ),
    );
  }

  Widget _setup() => ListView(children: [
        if (!permitted)
          Card(
            color: Colors.amber.shade100,
            child: ListTile(
              title: const Text('Izin Usage Access diperlukan'),
              subtitle: const Text('Agar Satu Dulu dapat mendeteksi aplikasi yang sedang dibuka.'),
              trailing: TextButton(
                onPressed: () async {
                  await FocusPlatform.openPermissionSettings();
                  permitted = await FocusPlatform.hasPermission();
                  setState(() {});
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        Text('Set Timer', style: Theme.of(context).textTheme.titleMedium),
        Text('$minutes menit', style: Theme.of(context).textTheme.displaySmall),
        Slider(value: minutes.toDouble(), min: 5, max: 180, divisions: 35, label: '$minutes', onChanged: (v) => setState(() => minutes = v.round())),
        Wrap(spacing: 8, children: [for (final m in [15, 25, 45, 60]) ActionChip(label: Text('$m m'), onPressed: () => setState(() => minutes = m))]),
        const SizedBox(height: 20),
        Text('Choose Apps & Websites', style: Theme.of(context).textTheme.titleMedium),
        for (final a in apps)
          CheckboxListTile(title: Text(a.name), value: a.on, onChanged: (v) => setState(() => a.on = v!)),
        Row(children: [
          Expanded(child: TextField(controller: custom, decoration: const InputDecoration(hintText: 'Tambah (mis. shopee, twitter)'))),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              final t = custom.text.trim().toLowerCase();
              if (t.isEmpty) return;
              setState(() => apps.add(Blocked(t, [t], on: true)));
              custom.clear();
            },
          ),
        ]),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: apps.any((a) => a.on) ? start : null,
          icon: const Icon(Icons.play_arrow),
          label: const Padding(padding: EdgeInsets.all(14), child: Text('Mulai Belajar')),
        ),
      ]);

  Widget _focus() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Focus Mode aktif', style: TextStyle(fontSize: 16)),
        Text(fmt(remaining), style: const TextStyle(fontSize: 84, fontWeight: FontWeight.w300)),
        LinearProgressIndicator(value: 1 - remaining / total),
        const SizedBox(height: 16),
        Text('Percobaan membuka aplikasi terbatas: $attempts'),
        if (warning.isNotEmpty && inViolation)
          Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(14), child: Text(warning, textAlign: TextAlign.center))),
        const SizedBox(height: 32),
        OutlinedButton(onPressed: _stopEarly, child: const Text('Hentikan sesi (darurat)')),
      ]);

  Widget _report() => ListView(children: [
        Icon(completed ? Icons.celebration : Icons.flag, size: 56),
        Center(child: Text(completed ? 'Sesi selesai! Pembatasan berakhir.' : 'Sesi dihentikan lebih awal', style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 16),
        Card(child: Column(children: [
          ListTile(title: const Text('Durasi belajar'), trailing: Text('${fmt(studied)} dari ${fmt(total)}')),
          ListTile(title: const Text('Percobaan membuka aplikasi/website terbatas'), trailing: Text('$attempts')),
          ListTile(title: const Text('Status'), trailing: Text(completed ? 'Selesai' : 'Belum selesai')),
          ListTile(title: const Text('Skor fokus'), subtitle: Text(scoreLabel), trailing: Text('$score', style: Theme.of(context).textTheme.headlineMedium)),
        ])),
        const SizedBox(height: 8),
        const Text('Skor = persentase waktu belajar yang ditempuh, dikurangi 10 poin untuk setiap percobaan membuka aplikasi terbatas.', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => setState(() => stage = Stage.setup), child: const Text('Sesi baru')),
      ]);
}
