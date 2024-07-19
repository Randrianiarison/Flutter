import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liste Livres',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> livres = [];
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  TextEditingController titreController = TextEditingController();
  TextEditingController auteurController = TextEditingController();
  TextEditingController anneeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLivres();
  }

  Future<void> fetchLivres() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://127.0.0.1:8000/api/livres');

    try {
      final response = await http.get(url);
      print('HTTP Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body;
        dynamic jsonResponse = jsonDecode(body);

        setState(() {
          livres = jsonResponse;
          isLoading = false;
        });
        print('Livres fetched successfully');
      } else {
        print('Failed to load livres: ${response.reasonPhrase}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching livres: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteLivre(int id) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/livres/$id');

    try {
      final response = await http.delete(url);
      print('HTTP Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Si la suppression est réussie, rechargez la liste des livres
        fetchLivres();
        print('Livre supprimé avec succès');
      } else {
        print('Failed to delete livre: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error deleting livre: $e');
    }
  }

  Future<void> addLivre() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    final newLivre = {
      'titre': titreController.text,
      'auteur': auteurController.text,
      'genre': anneeController.text,
    };

    final url = Uri.parse('http://127.0.0.1:8000/api/livres');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(newLivre),
      );

      print('HTTP Status Code: ${response.statusCode}');

      if (response.statusCode == 201) {
        titreController.clear();
        auteurController.clear();
        anneeController.clear();

        // Si l'ajout est réussi, rechargez la liste des livres
        fetchLivres();
        Navigator.of(context).pop(); // Fermer la modal
        print('Livre ajouté avec succès');
      } else {
        print('Failed to add livre: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error adding livre: $e');
    }
  }

  Future<void> updateLivre(int id) async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    final updatedLivre = {
      'titre': titreController.text,
      'auteur': auteurController.text,
      'genre': anneeController.text,
    };

    final url = Uri.parse('http://127.0.0.1:8000/api/livres/$id');

    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedLivre),
      );

      print('HTTP Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        titreController.clear();
        auteurController.clear();
        anneeController.clear();

        // Si la mise à jour est réussie, rechargez la liste des livres
        fetchLivres();
        Navigator.of(context).pop(); // Fermer la modal
        print('Livre modifié avec succès');
      } else {
        print('Failed to update livre: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error updating livre: $e');
    }
  }

  void showEditDialog(Map<String, dynamic> livre) {
    titreController.text = livre['titre'];
    auteurController.text = livre['auteur'];
    anneeController.text = livre['genre'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le livre'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: titreController,
                    decoration: InputDecoration(labelText: 'Titre'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le titre du livre';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: auteurController,
                    decoration: InputDecoration(labelText: 'Auteur'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le nom de l\'auteur';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: anneeController,
                    decoration: InputDecoration(labelText: 'Genre'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le genre du livre';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                updateLivre(livre['id']);
              },
              child: Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste Livres'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : livres.isEmpty
          ? Center(child: Text('Aucun livre trouvé'))
          : ListView.builder(
        itemCount: livres.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: Icon(Icons.book),
              title: Text(
                livres[index]['titre'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(livres[index]['auteur']),
                  SizedBox(height: 4),
                  Text('Genre: ${livres[index]['genre']}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showEditDialog(livres[index]);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirmer la suppression'),
                            content: Text('Voulez-vous vraiment supprimer ce livre ?'),
                            actions: [
                              TextButton(
                                child: Text('Annuler'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Supprimer'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  deleteLivre(livres[index]['id']);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Ajouter un livre'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: titreController,
                          decoration: InputDecoration(labelText: 'Titre'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le titre du livre';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: auteurController,
                          decoration: InputDecoration(labelText: 'Auteur'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nom de l\'auteur';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: anneeController,
                          decoration: InputDecoration(labelText: 'Genre'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le genre du livre';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: addLivre,
                    child: Text('Ajouter'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
