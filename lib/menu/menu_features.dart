import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io';

export 'my_account_screen.dart';

const _bg = Color(0xFF030D1B);
const _panel = Color(0xFF10243D);
const _cyan = Color(0xFF20D9E8);
const _muted = Color(0xFF9AACC1);

class _MenuPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _MenuPage({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(backgroundColor: const Color(0xFF071426), foregroundColor: Colors.white, title: Text(title)),
    body: SafeArea(child: child),
  );
}

class ShareBujjiScreen extends StatelessWidget {
  const ShareBujjiScreen({super.key});
  static const _message = 'Meet BUJJI AI – your personal AI assistant! Chat, explore tools and learn with BUJJI AI.';
  @override
  Widget build(BuildContext context) => _MenuPage(
    title: 'Share BUJJI AI', icon: Icons.share_rounded,
    child: Padding(padding: const EdgeInsets.all(22), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.rocket_launch_rounded, color: _cyan, size: 54),
        const SizedBox(height: 18),
        const Text('Share BUJJI AI with your friends', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Invite people to try BUJJI AI. The Play Store link can be added after the app is published.', style: TextStyle(color: _muted, height: 1.5)),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => Share.share(_message),
          icon: const Icon(Icons.share), label: const Text('Share app message'),
          style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: _bg, padding: const EdgeInsets.all(14)),
        )),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () async { await Clipboard.setData(const ClipboardData(text: _message)); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied'))); },
          icon: const Icon(Icons.copy), label: const Text('Copy message')),
      ],
    )),
  );
}

class BujjiPremiumScreen extends StatelessWidget {
  const BujjiPremiumScreen({super.key});
  @override
  Widget build(BuildContext context) => _MenuPage(title: 'BUJJI Premium', icon: Icons.workspace_premium_rounded,
    child: ListView(padding: const EdgeInsets.all(18), children: [
      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFC857), size: 64),
      const SizedBox(height: 12),
      const Text('BUJJI Premium', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('More power for your everyday AI tasks.', textAlign: TextAlign.center, style: TextStyle(color: _muted)),
      const SizedBox(height: 22),
      _benefit(Icons.auto_awesome, 'More AI usage', 'A future premium usage allowance'),
      _benefit(Icons.translate, 'Advanced language tools', 'Enhanced voice and translation experiences'),
      _benefit(Icons.school, 'Learning tools', 'Expanded learning and revision features'),
      _benefit(Icons.support_agent, 'Priority support', 'A dedicated support experience'),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(14)),
        child: const Text('Subscriptions and payments are not connected yet. No payment will be taken from this screen. Plans and pricing will appear here when billing is ready.', style: TextStyle(color: _muted, height: 1.5))),
    ]));
  static Widget _benefit(IconData icon, String title, String detail) => ListTile(
    leading: Icon(icon, color: _cyan), title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    subtitle: Text(detail, style: const TextStyle(color: _muted)));
}

class VoiceTranslationScreen extends StatefulWidget {
  const VoiceTranslationScreen({super.key});
  @override
  State<VoiceTranslationScreen> createState() => _VoiceTranslationScreenState();
}
class _VoiceTranslationScreenState extends State<VoiceTranslationScreen> {
  final _speech = SpeechToText();
  final _input = TextEditingController();
  bool _ready = false, _listening = false, _working = false;
  String _target = 'English', _result = '';
  @override
  void dispose() { _speech.cancel(); _input.dispose(); super.dispose(); }
  Future<void> _listen() async {
    if (_listening) { await _speech.stop(); if (mounted) setState(() => _listening = false); return; }
    _ready = await _speech.initialize();
    if (!_ready) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition is unavailable. Check microphone permission and device speech service.'))); return; }
    await _speech.listen(onResult: (r) { if (mounted) setState(() => _input.text = r.recognizedWords); }, listenFor: const Duration(seconds: 60));
    if (mounted) setState(() => _listening = true);
  }
  Future<void> _translate() async {
    final text = _input.text.trim(); if (text.isEmpty || _working) return;
    setState(() { _working = true; _result = ''; });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final req = await client.postUrl(Uri.parse('https://bujji-ai-api.bujji-neural-ai.workers.dev/chat')).timeout(const Duration(seconds: 30));
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({'message': 'Translate the following text into $_target. Preserve its meaning and tone. Return only the translation:\n$text', 'history': <Map<String,String>>[]})));
      final response = await req.close().timeout(const Duration(seconds: 60));
      final body = await utf8.decoder.bind(response).join();
      final data = jsonDecode(body);
      if (response.statusCode < 200 || response.statusCode >= 300 || data is! Map || data['success'] != true) throw Exception('Translation service is unavailable.');
      if (mounted) setState(() => _result = (data['reply'] ?? '').toString());
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Translation failed: $e'))); }
    finally { client.close(force: true); if (mounted) setState(() => _working = false); }
  }
  @override
  Widget build(BuildContext context) => _MenuPage(title: 'Voice & Translation', icon: Icons.mic_rounded,
    child: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Speak or type to translate', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('Speech recognition uses the speech service available on your device. Translation needs an internet connection.', style: TextStyle(color: _muted, height: 1.4)),
      const SizedBox(height: 16),
      TextField(controller: _input, maxLines: 5, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Speak or enter text...', hintStyle: const TextStyle(color: _muted), filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _listen, icon: Icon(_listening ? Icons.stop : Icons.mic), label: Text(_listening ? 'Stop listening' : 'Speak'))),
        const SizedBox(width: 10),
        Expanded(child: DropdownButtonFormField<String>(value: _target, dropdownColor: _panel, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Translate to', labelStyle: TextStyle(color: _muted)), items: ['Telugu','English','Hindi','Tamil','Kannada','Malayalam','Spanish','French'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(), onChanged:(v){if(v!=null)setState(()=>_target=v);})),
      ]),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _working ? null : _translate, style: ElevatedButton.styleFrom(backgroundColor: _cyan, foregroundColor: _bg), child: Text(_working ? 'Translating...' : 'Translate'))),
      if (_result.isNotEmpty) ...[const SizedBox(height: 20), const Text('TRANSLATION', style: TextStyle(color: _cyan, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(14)), child: SelectableText(_result, style: const TextStyle(color: Colors.white, height: 1.5))), TextButton.icon(onPressed:()=>Clipboard.setData(ClipboardData(text:_result)), icon:const Icon(Icons.copy), label:const Text('Copy translation'))]
    ]));
}

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});
  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}
class _MyLearningScreenState extends State<MyLearningScreen> {
  final _controller = TextEditingController();
  List<String> _items = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p=await SharedPreferences.getInstance(); if(mounted)setState(()=>_items=p.getStringList('learning_items')??[]); }
  Future<void> _add() async { final v=_controller.text.trim(); if(v.isEmpty)return; final p=await SharedPreferences.getInstance(); final next=[v,..._items]; await p.setStringList('learning_items',next); if(mounted)setState(()=>_items=next); _controller.clear(); }
  Future<void> _delete(int i) async { final next=[..._items]..removeAt(i); final p=await SharedPreferences.getInstance(); await p.setStringList('learning_items',next); if(mounted)setState(()=>_items=next); }
  @override
  void dispose(){_controller.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>_MenuPage(title:'My Learning',icon:Icons.menu_book_rounded,child:Column(children:[
    Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Your personal learning notebook',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
      const SizedBox(height:6),const Text('Save words, meanings, phrases or notes here. Items stay on this device until you delete them.',style:TextStyle(color:_muted)),
      const SizedBox(height:12),TextField(controller:_controller,style:const TextStyle(color:Colors.white),decoration:InputDecoration(hintText:'Add a word, meaning or learning note',hintStyle:const TextStyle(color:_muted),filled:true,fillColor:_panel,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)))),
      const SizedBox(height:8),SizedBox(width:double.infinity,child:ElevatedButton(onPressed:_add,style:ElevatedButton.styleFrom(backgroundColor:_cyan,foregroundColor:_bg),child:const Text('Save to My Learning')))
    ])),
    Expanded(child:_items.isEmpty?const Center(child:Text('No saved learning items yet.',style:TextStyle(color:_muted))):ListView.builder(itemCount:_items.length,itemBuilder:(c,i)=>Card(color:_panel,margin:const EdgeInsets.symmetric(horizontal:16,vertical:5),child:ListTile(title:Text(_items[i],style:const TextStyle(color:Colors.white)),trailing:IconButton(icon:const Icon(Icons.delete_outline,color:Colors.redAccent),onPressed:()=>_delete(i)))))),
  ]));
}

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});
  @override
  State<AppSettingsScreen> createState()=>_AppSettingsScreenState();
}
class _AppSettingsScreenState extends State<AppSettingsScreen>{
  String _language='Auto',_theme='Dark'; bool _notifications=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{final p=await SharedPreferences.getInstance();if(mounted)setState((){_language=p.getString('app_language')??'Auto';_theme=p.getString('app_theme')??'Dark';_notifications=p.getBool('app_notifications')??true;});}
  Future<void> _save(String key,Object value)async{final p=await SharedPreferences.getInstance();if(value is String)await p.setString(key,value);if(value is bool)await p.setBool(key,value);}
  @override Widget build(BuildContext context)=>_MenuPage(title:'App Settings',icon:Icons.settings_rounded,child:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Personalise BUJJI AI',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
    const SizedBox(height:14),
    DropdownButtonFormField<String>(value:_language,dropdownColor:_panel,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(labelText:'App language preference',labelStyle:TextStyle(color:_muted)),items:['Auto','English','Telugu','Hindi'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null){setState(()=>_language=v);_save('app_language',v);}}),
    const SizedBox(height:16),
    DropdownButtonFormField<String>(value:_theme,dropdownColor:_panel,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(labelText:'Appearance preference',labelStyle:TextStyle(color:_muted)),items:['Dark','System','Light'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null){setState(()=>_theme=v);_save('app_theme',v);}}),
    SwitchListTile(title:const Text('Notifications preference',style:TextStyle(color:Colors.white)),subtitle:const Text('Saved as your preference; system notifications are not configured yet.',style:TextStyle(color:_muted)),value:_notifications,activeColor:_cyan,onChanged:(v){setState(()=>_notifications=v);_save('app_notifications',v);}),
    const SizedBox(height:12),const Text('These preferences are stored on this device. Some settings will affect app behaviour after their related features are connected.',style:TextStyle(color:_muted,height:1.5))
  ]));
}
