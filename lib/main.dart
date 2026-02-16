import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'admin_data_viewer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niche AI Companion',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/chat': (context) => const ChatScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/admin/data': (context) => const AdminDataViewer(),
      },
    );
  }
}

// Simple Auth Gate to redirect between Onboarding and Chat
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement actual Auth check
    // For MVP, we can check a shared preference flag 'onboarding_complete'
    bool onboardingComplete = false; 
    
    if (!onboardingComplete) {
      return const OnboardingScreen();
    }
    return const ChatScreen();
  }
}


// ----------------------------------------------------------------------
// Constants & Data Models
// ----------------------------------------------------------------------
const List<String> userPersonas = [
  'INTJ - Strategist / 전략가형',
  'ENFP - Inspirer / 영감 추구형',
  'ISTJ - Realist / 현실주의자',
  'INFP - Idealist / 이상주의자',
  'ESTP - Doer / 행동가형',
];

const List<String> adminPersonas = [
  'Strict PT Coach / 엄격한 PT 쌤',
  'Warm Therapist / 다정한 상담사',
  'Strategic Performance Coach / 전략가형 코치',
  'Motivational Speaker / 동기부여 연설가',
  'Reality Check Manager / 현실 점검 매니저',
];

// ... (previous code until OnboardingScreen)

// ----------------------------------------------------------------------
// 1. Onboarding Screen
// ----------------------------------------------------------------------
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _goalController = TextEditingController();
  final _whyController = TextEditingController();
  String? _selectedPersona;
  TimeOfDay? _morningTrigger;
  TimeOfDay? _eveningTrigger;
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_goalController.text.isEmpty || _whyController.text.isEmpty || _selectedPersona == null) return;

    setState(() => _isLoading = true);
    
    try {
      // Anonymously sign in for MVP simplicity
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'goal': _goalController.text,
        'why': _whyController.text,
        'morning_trigger': _morningTrigger?.format(context),
        'evening_trigger': _eveningTrigger?.format(context),
        'user_persona': _selectedPersona,
        'created_at': FieldValue.serverTimestamp(),
        'motivation_level': 5, // Default medium
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Your Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What is your ONE primary goal?\n가장 중요한 목표 하나는 무엇인가요?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(
                hintText: "e.g., Write a book / 예: 책 쓰기",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Why creates Motivation.\n'왜'는 강력한 동기를 만듭니다.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _whyController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Why do you want this? / 왜 이 목표를 이루고 싶나요?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Personality Type (MBTI)\n성향을 선택해주세요.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedPersona,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Select your type / 유형 선택",
              ),
              items: userPersonas.map((persona) {
                return DropdownMenuItem(value: persona, child: Text(persona));
              }).toList(),
              onChanged: (val) => setState(() => _selectedPersona = val),
            ),
            const SizedBox(height: 30),
            const Text(
              "Set Trigger Times (Kairos)\n트리거 시간 설정 (카이로스)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Morning Priming / 아침 프라이밍"),
              subtitle: Text(_morningTrigger?.format(context) ?? "Not set / 설정 안 됨"),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                if (time != null) setState(() => _morningTrigger = time);
              },
            ),
            ListTile(
              title: const Text("Evening Reflection / 저녁 회고"),
              subtitle: Text(_eveningTrigger?.format(context) ?? "Not set / 설정 안 됨"),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
                if (time != null) setState(() => _eveningTrigger = time);
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text("Start Journey / 여정 시작하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. Main Chat Interface
// ----------------------------------------------------------------------
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Save User Message
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('messages').add({
      'text': text,
      'sender': 'user',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Note: The AI response will be handled by a Cloud Function trigger (or client-side call if preferred for MVP speed)
    // For this MVP, we rely on the Admin Panel (Wizard of Oz) or Cloud Function to reply.
  }

  void _sendEmergency() async {
     final user = _auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('messages').add({
      'text': "EMERGENCY: I'm Overwhelmed / 너무 벅차요", // Special keyword for AI/Admin
      'sender': 'user',
      'is_emergency': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Error: No User Logged In")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Companion / 동반자'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isUser = data['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[900] : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(data['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Emergency Button
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.red[900]!.withOpacity(0.2),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sendEmergency,
                    icon: const Icon(Icons.sos, color: Colors.red),
                    label: const Text(
                      "I'm Overwhelmed / 너무 벅차요",
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
          // Input Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message... / 메시지를 입력하세요...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 3. Wizard of Oz Admin Panel
// ----------------------------------------------------------------------
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wizard Admin Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'View Synthetic Data',
            onPressed: () => Navigator.pushNamed(context, '/admin/data'),
          ),
        ],
      ),
      body: Row(
        children: [
          // User List Stream
          SizedBox(
            width: 250,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('created_at', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['goal'] ?? 'No Goal'),
                      subtitle: Text(doc.id.substring(0, 5)),
                      selected: _selectedUserId == doc.id,
                      onTap: () => setState(() => _selectedUserId = doc.id),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // Chat View & Override
          Expanded(
            child: _selectedUserId == null 
              ? const Center(child: Text("Select a user to coach"))
              : AdminChatView(userId: _selectedUserId!),
          ),
        ],
      ),
    );
  }
}

class AdminChatView extends StatefulWidget {
  final String userId;
  const AdminChatView({super.key, required this.userId});

  @override
  State<AdminChatView> createState() => _AdminChatViewState();
}

class _AdminChatViewState extends State<AdminChatView> {
  final _adminMsgController = TextEditingController();
  String _selectedAdminPersona = adminPersonas[0];

  void _sendAdminMessage() async {
    final text = _adminMsgController.text.trim();
    if (text.isEmpty) return;
    _adminMsgController.clear();

    await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('messages').add({
      'text': text,
      'sender': 'ai', // Mimic AI
      'admin_persona': _selectedAdminPersona,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final docs = snapshot.data!.docs;
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                   final data = docs[index].data() as Map<String, dynamic>;
                   final isUser = data['sender'] == 'user';
                   return Align(
                     alignment: isUser ? Alignment.centerLeft : Alignment.centerRight, // Admin view: User left, AI right
                     child: Container(
                       margin: const EdgeInsets.symmetric(vertical: 4),
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: isUser ? Colors.grey[800] : Colors.blue[900],
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         "${isUser ? '[USER]' : '[AI]'} ${data['text']}",
                         style: const TextStyle(color: Colors.white),
                       ),
                     ),
                   );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text("Override AI Response / AI 대신 답변하기:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedAdminPersona,
                isExpanded: true,
                items: adminPersonas.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAdminPersona = val);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adminMsgController,
                      decoration: const InputDecoration(
                        labelText: "Manual Message",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _sendAdminMessage,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("SEND MANUAL"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
