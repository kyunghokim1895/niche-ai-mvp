import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'admin_data_viewer.dart';

import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/glass_container.dart';
import 'shared/widgets/primary_button.dart';

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
      theme: AppTheme.darkTheme,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withOpacity(0.1),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Design Your\nCompanion",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's personalize your journey.",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 48),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("What is your primary goal?", "가장 중요한 목표 하나는 무엇인가요?"),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _goalController,
                        decoration: const InputDecoration(
                          hintText: "e.g., Write a book",
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Why creates Motivation.", "'왜'는 강력한 동기를 만듭니다."),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _whyController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Why do you want this?",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSectionTitle("Personality Type (MBTI)", "성향을 선택해주세요."),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedPersona,
                        decoration: const InputDecoration(hintText: "Select your type"),
                        items: userPersonas.map((persona) {
                          return DropdownMenuItem(value: persona, child: Text(persona));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPersona = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSectionTitle("Set Trigger Times", "트리거 시간 설정"),
                      const SizedBox(height: 8),
                      _buildTimeTile("Morning Priming", _morningTrigger, (time) => setState(() => _morningTrigger = time)),
                      const Divider(color: Colors.white10),
                      _buildTimeTile("Evening Reflection", _eveningTrigger, (time) => setState(() => _eveningTrigger = time)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: "Start Journey",
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String en, String ko) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(en, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(ko, style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildTimeTile(String title, TimeOfDay? time, Function(TimeOfDay) onSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(
        time?.format(context) ?? "Not set",
        style: TextStyle(color: time == null ? AppTheme.textMuted : AppTheme.secondary),
      ),
      trailing: const Icon(Icons.access_time, size: 20),
      onTap: () async {
        final selected = await showTimePicker(context: context, initialTime: time ?? const TimeOfDay(hour: 8, minute: 0));
        if (selected != null) onSelected(selected);
      },
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Companion',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white70),
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              AppTheme.primary.withOpacity(0.15),
              AppTheme.background,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 20),
            // AI Status Orb Placeholder
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isUser = data['sender'] == 'user';
                      return _buildMessageBubble(data['text'] ?? '', isUser);
                    },
                  );
                },
              ),
            ),
            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: GlassContainer(
          borderRadius: 18,
          opacity: isUser ? 0.2 : 0.1,
          color: isUser ? AppTheme.primary : AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: 28,
                  opacity: 0.1,
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Speak your mind...",
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Emergency SOS
          GestureDetector(
            onTap: _sendEmergency,
            child: Text(
              "Too overwhelmed? Get help",
              style: TextStyle(
                color: AppTheme.accent.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
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
