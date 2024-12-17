import 'package:flutter/material.dart';

class TagsDialog extends StatefulWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final Function(List<String>) onTagsSelected;

  const TagsDialog({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onTagsSelected,
  });

  @override
  TagsDialogState createState() => TagsDialogState();
}

class TagsDialogState extends State<TagsDialog> {
  late List<String> selectedTagsTemp;
  final TextEditingController _newTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedTagsTemp = List<String>.from(widget.selectedTags);
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
      backgroundColor: Colors.white,
      title: const Center(
        child: Text(
          'Selecione as Tags',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: widget.allTags.map((tag) {
                    return FilterChip(
                      backgroundColor: Colors.white,
                      selectedColor: const Color.fromARGB(255, 92, 181, 255),
                      label: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      selected: selectedTagsTemp.contains(tag),
                      onSelected: (bool selected) {
                        setState(() {
                          selected
                              ? selectedTagsTemp.add(tag)
                              : selectedTagsTemp.remove(tag);
                          widget.onTagsSelected(selectedTagsTemp);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newTagController,
                  decoration: InputDecoration(
                    labelText: 'Criar nova tag',
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    hintText: 'Digite o nome da nova tag',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0, horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                          color: Colors.blueAccent, width: 1.5),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        if (!widget.allTags.contains(value)) {
                          widget.allTags.add(value);
                          selectedTagsTemp.add(value);
                          widget.onTagsSelected(selectedTagsTemp);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Não foi possível criar a tag. Já existe uma tag com o mesmo nome.'),
                            ),
                          );
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
          ),
        ),
        // ElevatedButton(
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.blue,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //   ),
        //   onPressed: () {
        //     widget.onTagsSelected(selectedTagsTemp);
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(
        //           content: Text("As alterações em tags foram salvas.")),
        //     );
        //   },
        //   child: const Text(
        //     'Aplicar',
        //     style: TextStyle(
        //       color: Colors.white,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
