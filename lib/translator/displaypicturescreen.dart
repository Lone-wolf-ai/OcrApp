import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard functionality
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ocr_extra/constant/list.dart'; // Import your language list
import 'package:ocr_extra/translator/widget/showimage.dart';
import 'package:translator/translator.dart';
import 'package:velocity_x/velocity_x.dart'; // Import the translator package

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  String recognizedText = '';
  String errorMessage = '';
  String language = '';
  String selectedLanguageCode = '';
  String translatedText = ''; 

  @override
  void initState() {
    super.initState();
    _recognizeText();
  }

  Future<void> _recognizeText() async {
    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedTextResult =
          await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      setState(() {
        if (recognizedTextResult.text.isEmpty) {
          errorMessage = 'No text found in the image.';
        } else {
          recognizedText = recognizedTextResult.text;
          _identifyLanguage(recognizedText);
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error recognizing text: $e';
      });
    }
  }

  Future<void> _identifyLanguage(String text) async {
    try {
      final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final List<IdentifiedLanguage> possibleLanguages =
          await languageIdentifier.identifyPossibleLanguages(text);
      languageIdentifier.close();

      setState(() {
        language = possibleLanguages.isNotEmpty
            ? possibleLanguages.first.languageTag
            : 'Unknown';
        selectedLanguageCode = language;
      });
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Something Went Wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      });
    }
  }

  void _showLanguageMenu() async {
    final selectedCode = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 100,
        kToolbarHeight,
        0,
        0,
      ),
      items: languageMap.entries
          .map((entry) => PopupMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ))
          .toList(),
      elevation: 8.0,
    );

    if (selectedCode != null) {
      setState(() {
        selectedLanguageCode = selectedCode;
        language = languageMap[selectedCode] ?? 'Unknown Language';
      });
      _translateText(recognizedText);
    }
  }

  Future<void> _translateText(String text) async {
    if (text.isEmpty) return;

    final translator = GoogleTranslator();
    try {
      final translation =
          await translator.translate(text, to: selectedLanguageCode);
      setState(() {
        translatedText = translation.text;
      });
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Error translating text',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      });
    }
  }

  void _copyToClipboard(String source) {
    if (recognizedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: source));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "There's no text to copy",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Semantics(
          label:"Scan Result",
          child: Text(
            'Scan Result',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[900]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 0.02 * height),
              ShowImage(imagePath: widget.imagePath),
              SizedBox(height: 0.02 * height),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                height: 0.06 * height,
                child: Semantics(
                  label: "Language: ${languageMap[selectedLanguageCode] ?? 'Unknown'}",
                  child: Text(
                    "Language: ${languageMap[selectedLanguageCode] ?? 'Unknown'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 0.02 * height),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                height: 0.06 * height,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label:"Extracted Text" ,
                      child: const Text(
                        "Extracted Text",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            Semantics(
                              label: "Click here to copy",
                              child: IconButton(
                                tooltip: "Copy",
                                onPressed: () => _copyToClipboard(recognizedText),
                                icon: const Icon(
                                  Iconsax.copy,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                        Semantics(
                          label: "Click here to translate",
                          child: IconButton(
                            onPressed: _showLanguageMenu,
                            icon: const Icon(
                              Iconsax.translate,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 0.02 * height),
              if (recognizedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.only(
                      top: 24, bottom: 24, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(width: 1),
                  ),
                  width: double.infinity,
                  child: Semantics(
                    label: recognizedText,
                    child: Text(
                      recognizedText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              if (translatedText.isNotEmpty)
                Column(
                  children: [
                    SizedBox(height: 0.02*height,),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: double.infinity,
                      height: 0.06 * height,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Semantics(
                            label: "Translated Text",
                            child: const Text(
                              "Translated Text",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Column(
                                children: [
                                  Semantics(
                                    label: "click here to copy to clip board",
                                    child: IconButton(
                                      tooltip: "Copy",
                                      onPressed: () =>
                                          _copyToClipboard(translatedText),
                                      icon: const Icon(
                                        Iconsax.copy,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 0.02 * height,
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(width: 1),
                      ),
                      width: double.infinity,
                      child: Semantics(
                        label:translatedText ,
                        child: Text(
                          translatedText,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 0.04 * height,
                    ),
                  ],
                ),
              if (errorMessage.isNotEmpty)
                Center(
                  child: Semantics(
                    label: errorMessage,
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
