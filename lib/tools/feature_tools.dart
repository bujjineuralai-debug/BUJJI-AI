import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../services/bujji_api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

const _bg=Color(0xFF06101E), _panelColor=Color(0xFF0B1B2D), _cyan=Color(0xFF25B8FF), _gold=Color(0xFFFFC857);
const _api='https://bujji-ai-api.bujji-neural-ai.workers.dev';

class _Page extends StatelessWidget {
  final String title, intro; final Widget child;
  const _Page(this.title,this.intro,this.child);
  @override Widget build(BuildContext c)=>Scaffold(backgroundColor:_bg,appBar:AppBar(backgroundColor:_bg,foregroundColor:Colors.white,title:Text(title)),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(intro,style:const TextStyle(color:Colors.white70,height:1.5)),const SizedBox(height:18),child]))));
}
Widget _panel(Widget child)=>Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:_panelColor,borderRadius:BorderRadius.circular(18),border:Border.all(color:_cyan.withOpacity(.2))),child:child);
Widget _button(String label,IconData icon,VoidCallback? action,{bool busy=false})=>SizedBox(width:double.infinity,child:ElevatedButton.icon(onPressed:busy?null:action,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Icon(icon),label:Text(label),style:ElevatedButton.styleFrom(backgroundColor:_cyan,foregroundColor:_bg,padding:const EdgeInsets.symmetric(vertical:14))));

class BrainChallengeScreen extends StatefulWidget { const BrainChallengeScreen({super.key}); @override State<BrainChallengeScreen> createState()=>_BrainChallengeScreenState(); }
class _BrainChallengeScreenState extends State<BrainChallengeScreen>{
 final qs=<Map<String,Object>>[
 {'q':'What comes next? 2, 4, 8, 16, ...','a':['18','24','32','30'],'c':2,'why':'ప్రతి సంఖ్యను 2తో గుణిస్తున్నాం.'},
 {'q':'Which one is different?','a':['Apple','Mango','Carrot','Banana'],'c':2,'why':'Carrot ఒక కూరగాయ; మిగతావి పండ్లు.'},
 {'q':'A clock shows 3:00. What is the angle between its hands?','a':['45°','90°','120°','180°'],'c':1,'why':'3 గంటలకు కోణం 90 డిగ్రీలు.'},
 {'q':'5 machines make 5 toys in 5 minutes. 100 machines make 100 toys in how many minutes?','a':['5','20','100','1'],'c':0,'why':'ప్రతి యంత్రం 5 నిమిషాల్లో ఒక బొమ్మ చేస్తుంది.'},
 {'q':'Which number is the odd one out?','a':['9','16','25','30'],'c':3,'why':'9, 16, 25 perfect squares; 30 కాదు.'},
 {'q':'You have 3 apples and take away 2. How many do you have?','a':['1','2','3','5'],'c':1,'why':'నువ్వు తీసుకున్నవి 2 కాబట్టి నీ దగ్గర 2 ఉంటాయి.'},
 {'q':'What is half of one quarter of 80?','a':['5','10','20','40'],'c':1,'why':'80లో నాలుగో వంతు 20; దాని సగం 10.'},
 {'q':'1, 1, 2, 3, 5, 8, ... What comes next?','a':['11','12','13','15'],'c':2,'why':'మునుపటి రెండు సంఖ్యలను కలుపుతాం.'},
 {'q':'Which is heavier: 1 kg iron or 1 kg cotton?','a':['Iron','Cotton','Both equal','Cannot tell'],'c':2,'why':'రెండింటి బరువు 1 కిలోగ్రామే.'},
 {'q':'17 sheep; all but 9 run away. How many remain?','a':['8','9','17','0'],'c':1,'why':'9 మినహా మిగతావి వెళ్లిపోయాయి.'}];
 int n=0,score=0; int? selected; bool done=false;
 void answer(int i){if(selected!=null)return;setState(() { selected=i; if(i==qs[n]['c']) score++; });}
 void next(){setState(() { if(n==9){done=true;}else{n++;selected=null;} });}
 void reset()=>setState(() { n=0; score=0; selected=null; done=false; });
 @override Widget build(BuildContext c)=>_Page('Brain Challenge','రోజూ చిన్న ప్రశ్నలతో నీ ఆలోచనా శక్తికి పరీక్ష పెట్టు.',_panel(done?Column(children:[const Icon(Icons.emoji_events,color:_gold,size:60),const Text('Challenge complete!',style:TextStyle(color:Colors.white,fontSize:22)),Text('నీ స్కోర్: '+score.toString()+' / 10',style:const TextStyle(color:_cyan,fontSize:20)),_button('Play Again',Icons.refresh,reset)]):Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Text('Question '+(n+1).toString()+' of 10',style:const TextStyle(color:_gold,fontWeight:FontWeight.bold)),const SizedBox(height:10),LinearProgressIndicator(value:(n+1)/10,color:_cyan),const SizedBox(height:18),Text(qs[n]['q'] as String,style:const TextStyle(color:Colors.white,fontSize:18)),
 const SizedBox(height:12),...List.generate(4,(i){final opts=qs[n]['a'] as List<String>;final correct=qs[n]['c'] as int;Color col=Colors.white12;if(selected!=null&&i==correct)col=Colors.green.withOpacity(.35);if(selected==i&&i!=correct)col=Colors.red.withOpacity(.35);return Padding(padding:const EdgeInsets.only(bottom:8),child:InkWell(onTap:selected==null?()=>answer(i):null,child:Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:col,borderRadius:BorderRadius.circular(12)),child:Text(String.fromCharCode(65+i)+'. '+opts[i],style:const TextStyle(color:Colors.white)))));}),
 if(selected!=null)...[Text(selected==qs[n]['c']?'Correct!':'Correct answer: '+(qs[n]['a'] as List<String>)[qs[n]['c'] as int],style:const TextStyle(color:_gold,fontWeight:FontWeight.bold)),Text(qs[n]['why'] as String,style:const TextStyle(color:Colors.white70)),_button(n==9?'See Result':'Next Question',Icons.arrow_forward,next)],Text('Score: '+score.toString(),style:const TextStyle(color:Colors.white54))
 ])));
}

class _VisionPage extends StatefulWidget {
  final bool room;
  const _VisionPage(this.room);

  @override
  State<_VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<_VisionPage> {
  final picker = ImagePicker();
  File? photo;
  String answer = '';
  bool busy = false;
  String? lastRequestId;

  void msg(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> pick(ImageSource source) async {
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        photo = File(file.path);
        answer = '';
      });
    } catch (error) {
      msg('ఫోటో తెరవలేకపోయాను: $error');
    }
  }

  Future<void> analyze() async {
    final selectedPhoto = photo;
    if (selectedPhoto == null || busy) return;

    setState(() {
      busy = true;
      answer = '';
      lastRequestId = null;
    });

    try {
      final bytes = await selectedPhoto.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('ఫోటో 5 MB కంటే తక్కువగా ఉండాలి.');
      }

      final prompt = widget.room
          ? 'Analyze this room photo. Reply in simple Telugu. Suggest furniture layout, lighting, wall colours, storage and low-budget improvements. Do not invent details.'
          : 'Carefully inspect the entire photo and identify the main visible subject. It may be an object, device, tool, vehicle, plant, animal, food, landmark, symbol, document or another real-world thing. Give the most specific common name supported by the visible evidence. Explain the visual clues that support the identification and its usual purpose. If multiple things are visible, identify the main one first and mention other clearly visible items only when useful. Do not give a vague answer when a reasonable identification is possible. If two possibilities genuinely look similar, give up to two candidates and explain the uncertainty instead of inventing certainty. If the photo is too blurry, dark or incomplete, say exactly what is unclear and ask for a clearer photo. Reply in natural, simple Telugu script using this structure: గుర్తించినది; ఎలా గుర్తించాను; ఉపయోగం / వివరణ; నమ్మకం (ఎక్కువ, మధ్యస్థం లేదా తక్కువ). Never invent details that cannot be seen or reliably inferred.';

      final apiResponse = await BujjiApiService.postJson(
        Uri.parse('$_api/vision'),
        {
          'image': 'data:image/jpeg;base64,${base64Encode(bytes)}',
          'question': prompt,
        },
      );
      final int statusCode = apiResponse.statusCode;
      final Map<String, dynamic> decoded = apiResponse.data;

      final traceId = decoded['requestId']?.toString();
      if (traceId != null && traceId.isNotEmpty) {
        lastRequestId = traceId;
        debugPrint('BUJJI Vision Trace ID: $traceId');
      }

      if (statusCode < 200 ||
          statusCode >= 300 ||
          decoded['success'] != true) {
        final message = decoded['error']?.toString() ??
            'AI విశ్లేషణ విఫలమైంది (HTTP $statusCode).';
        final detail = decoded['detail']?.toString();
        final requestId = decoded['requestId']?.toString();
        final suffix = detail != null && detail.isNotEmpty
            ? ' $detail'
            : '';
        final idText = requestId != null && requestId.isNotEmpty
            ? ' (ID: $requestId)'
            : '';
        throw Exception('$message$suffix$idText');
      }

      final text = decoded['answer']?.toString().trim() ?? '';
      if (text.isEmpty) {
        throw Exception('AI ఖాళీ సమాధానం పంపింది. మళ్లీ ప్రయత్నించండి.');
      }

      if (mounted) setState(() => answer = text);
    } catch (error) {
      msg('విశ్లేషణ విఫలమైంది: ${error.toString().replaceFirst("Exception: ", "")}');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Page(
      widget.room ? 'Room Designer' : 'What Is This?',
      widget.room
          ? 'గది ఫోటో ఆధారంగా రంగులు, ఫర్నిచర్ అమరిక, లైటింగ్ మరియు తక్కువ ఖర్చుతో మెరుగుదలలపై సూచనలు పొందు.'
          : 'వస్తువు ఫోటో తీసి లేదా గ్యాలరీ నుంచి ఎంచుకుని దాని గురించి తెలుసుకో.',
      Column(
        children: [
          _panel(
            Column(
              children: [
                if (photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      photo!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  SizedBox(
                    height: 170,
                    child: Center(
                      child: Icon(
                        widget.room
                            ? Icons.chair_alt
                            : Icons.photo_camera_back,
                        color: _cyan,
                        size: 60,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                _button(
                  widget.room ? 'Design My Room' : 'Identify This',
                  Icons.auto_awesome,
                  photo == null ? null : analyze,
                  busy: busy,
                ),
              ],
            ),
          ),
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 14),
            _panel(
              SelectableText(
                answer,
                style: const TextStyle(color: Colors.white, height: 1.5),
              ),
            ),
            if (lastRequestId != null && lastRequestId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  'Trace ID: $lastRequestId',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
          ],
          const Text(
            'విశ్లేషణ కోసం చిత్రం BUJJI AI సర్వర్‌కు పంపబడుతుంది. ఉచిత పరిమితి ముగిస్తే సేవ తాత్కాలికంగా ఆగవచ్చు.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class WhatIsThisScreen extends StatelessWidget {
  const WhatIsThisScreen({super.key});

  @override
  Widget build(BuildContext context) => const _VisionPage(false);
}

class RoomDesignerScreen extends StatelessWidget {
  const RoomDesignerScreen({super.key});

  @override
  Widget build(BuildContext context) => const _VisionPage(true);
}

class HandwritingToTextScreen extends StatefulWidget {
  const HandwritingToTextScreen({super.key});

  @override
  State<HandwritingToTextScreen> createState() =>
      _HandwritingToTextScreenState();
}

class _HandwritingToTextScreenState extends State<HandwritingToTextScreen> {
  final picker = ImagePicker();
  final recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  File? photo;
  String result = '';
  bool busy = false;

  void msg(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> pick(ImageSource source) async {
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      setState(() {
        photo = File(file.path);
        result = '';
      });
    } catch (error) {
      msg('ఫోటో తెరవలేకపోయాను: $error');
    }
  }

  Future<void> convertToText() async {
    final selectedPhoto = photo;
    if (selectedPhoto == null || busy) return;

    setState(() {
      busy = true;
      result = '';
    });

    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(selectedPhoto.path),
      );

      if (!mounted) return;
      final text = recognized.text.trim();
      setState(() => result = text);

      if (text.isEmpty) {
        msg('టెక్స్ట్ గుర్తించలేకపోయాను. ఫోటో స్పష్టంగా ఉందో చూడండి.');
      }
    } catch (error) {
      msg('టెక్స్ట్ మార్చడం విఫలమైంది: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Page(
      'Handwriting to Text',
      'చేతిరాత లేదా ముద్రించిన పేజీని ఫోటో తీసి లేదా గ్యాలరీ నుంచి ఎంచుకుని, తర్వాత Convert to Text నొక్కండి.',
      Column(
        children: [
          _panel(
            Column(
              children: [
                if (photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      photo!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  const SizedBox(
                    height: 120,
                    child: Center(
                      child: Icon(
                        Icons.document_scanner,
                        color: _cyan,
                        size: 58,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            busy ? null : () => pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            busy ? null : () => pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                if (photo != null)
                  _button(
                    'Convert to Text',
                    Icons.text_snippet,
                    busy ? null : convertToText,
                    busy: busy,
                  ),
                if (busy) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(color: _cyan),
                  const SizedBox(height: 6),
                  const Text(
                    'టెక్స్ట్ గుర్తిస్తోంది...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          if (result.isNotEmpty) ...[
            const SizedBox(height: 14),
            _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recognized Text',
                    style: TextStyle(
                      color: _cyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    result,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _button(
                    'Copy Text',
                    Icons.copy,
                    () async {
                      await Clipboard.setData(
                        ClipboardData(text: result),
                      );
                      msg('Text copied.');
                    },
                  ),
                ],
              ),
            ),
          ],
          const Text(
            'గమనిక: ఈ వెర్షన్‌లో Latin/English OCR మాత్రమే ఉంది. తెలుగు చేతిరాతకు ప్రస్తుతం మద్దతు లేదు. ఫలితం ఫోటో స్పష్టతపై ఆధారపడి ఉంటుంది.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class VoiceStudioScreen extends StatefulWidget{const VoiceStudioScreen({super.key});@override State<VoiceStudioScreen> createState()=>_VoiceStudioScreenState();}
class _VoiceStudioScreenState extends State<VoiceStudioScreen>{
 final recorder=AudioRecorder();final player=AudioPlayer();String? path;bool recording=false,playing=false;String status='రికార్డింగ్ ప్రారంభించడానికి బటన్ నొక్కండి.';
 void msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> start()async{try{if(!await recorder.hasPermission()){msg('Microphone permission అవసరం.');return;}final d=await getApplicationDocumentsDirectory();final p=d.path+'/bujji_voice_'+DateTime.now().millisecondsSinceEpoch.toString()+'.wav';await recorder.start(const RecordConfig(encoder:AudioEncoder.wav),path:p);if(mounted)setState(() { path=p; recording=true; status='Recording...'; });}catch(_){msg('రికార్డింగ్ ప్రారంభించలేకపోయాను.');}}
 Future<void> stop()async{try{final p=await recorder.stop();if(mounted)setState(() { recording=false; path=p??path; status='రికార్డింగ్ సేవ్ అయింది.'; });}catch(_){if(mounted)setState(()=>recording=false);}}
 Future<void> play()async{final p=path;if(p==null||!File(p).existsSync()){msg('ముందుగా రికార్డింగ్ చేయండి.');return;}try{await player.play(DeviceFileSource(p));if(mounted)setState(() { playing=true; status='Playing recording...'; });}catch(_){msg('ఆడియో ప్లే కాలేదు.');}}
 Future<void> stopPlay()async{await player.stop();if(mounted)setState(() { playing=false; status='Playback stopped.'; });}
 @override void initState(){super.initState();player.onPlayerComplete.listen((_){if(mounted)setState(() { playing=false; status='Playback complete.'; });});}
 @override void dispose(){recorder.dispose();player.dispose();super.dispose();}
 @override Widget build(BuildContext c)=>_Page('Voice Studio','నీ వాయిస్‌ను రికార్డ్ చేసి, సేవ్ చేసి, తిరిగి విను.',_panel(Column(children:[
 Container(height:145,width:145,decoration:BoxDecoration(shape:BoxShape.circle,color:_cyan.withOpacity(.1),border:Border.all(color:_cyan)),child:Icon(recording?Icons.mic:Icons.graphic_eq,color:recording?Colors.redAccent:_cyan,size:68)),
 Text(status,style:const TextStyle(color:Colors.white70)),_button(recording?'Stop Recording':'Start Recording',recording?Icons.stop:Icons.mic,recording?stop:start),
 Row(children:[Expanded(child:OutlinedButton.icon(onPressed:recording||path==null?null:play,icon:const Icon(Icons.play_arrow),label:const Text('Play'))),Expanded(child:OutlinedButton.icon(onPressed:playing?stopPlay:null,icon:const Icon(Icons.stop),label:const Text('Stop')))]),
 const Text('ఈ వెర్షన్‌లో రికార్డింగ్ మరియు ప్లేబ్యాక్ ఉన్నాయి. Voice effects / editing తదుపరి దశలో చేర్చవచ్చు.',style:TextStyle(color:Colors.white54,fontSize:12))
 ])));
}
