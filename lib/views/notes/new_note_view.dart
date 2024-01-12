import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabeseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _notesService = NotesService();
    _textController = TextEditingController();
    super.initState();
  }

  void textControllerListener() async{
    final note =_note;
    if(note == null){
      return;
    }
    final text = _textController.text;
    await _notesService.updateNote(
      note: note,
      text: text,
    );

  }

  void _setupTextControllerListener() {
    _textController.removeListener(_setupTextControllerListener);
    _textController.addListener(textControllerListener);
  }

  Future<DatabeseNote> createNewNote() async {
    final existingNote =_note;
    if (existingNote != null) {
      return existingNote;
    } 

    final currentUser = AuthService.firebase().currentUser;
    final email = currentUser?.email;
    final owner = await _notesService.getOrCreateUSer(email: email!);
    return await _notesService.createNote(
      owner: owner,    
    );
  }

  void _deleteNoteIfEmpty() async {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    } 
  }

  void _saveIfTextIsNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (text.isNotEmpty && note != null) {
      await _notesService.updateNote(
        note: note,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deleteNoteIfEmpty();
    _saveIfTextIsNotEmpty();
    _textController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        future: createNewNote(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
            
            //TODO: burada farklı olarak null olabilir opsiyonu koydum. DAtabase bağlantıfda ileride olabilcek sorunlar için dikkat edilmeli
              _note = snapshot.data as DatabeseNote?;
              _setupTextControllerListener();  
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Write your note here',
                 
                ),
                );
            default:
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

