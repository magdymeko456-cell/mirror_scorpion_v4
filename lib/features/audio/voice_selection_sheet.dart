import 'package:flutter/material.dart';
import '../../core/services/voice_selection_service.dart';

class VoiceSelectionSheet extends StatelessWidget {
  final dynamic voiceService;

  const VoiceSelectionSheet({super.key, required this.voiceService});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختيار محرك الصوت والتمرير',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('صوت سيف (مجاني)', style: TextStyle(color: Colors.white)),
            trailing: voiceService.selectedVoice == AppVoice.saif ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () {
              voiceService.selectVoice(AppVoice.saif);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('صوت سلمى (مجاني)', style: TextStyle(color: Colors.white)),
            trailing: voiceService.selectedVoice == AppVoice.salma ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () {
              voiceService.selectVoice(AppVoice.salma);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('صوت سما (مجاني)', style: TextStyle(color: Colors.white)),
            trailing: voiceService.selectedVoice == AppVoice.sama ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () {
              voiceService.selectVoice(AppVoice.sama);
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('صوت سارة (مجاني)', style: TextStyle(color: Colors.white)),
            trailing: voiceService.selectedVoice == AppVoice.sara ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () {
              voiceService.selectVoice(AppVoice.sara);
              Navigator.pop(context);
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.record_voice_over, color: Colors.amber),
            title: const Text('صوت تامر المنسوخ (PRO)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            subtitle: Text(
              voiceService.clonedVoicePath != null ? 'العينة مسجلة ومفعلة' : 'اضغط لتسجيل عينة الصوت الشخصية',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: voiceService.selectedVoice == AppVoice.ownerCloned ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () {
              voiceService.selectVoice(AppVoice.ownerCloned);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
