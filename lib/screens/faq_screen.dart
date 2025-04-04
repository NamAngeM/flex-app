// lib/screens/faq_screen.dart
import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  final List<Map<String, String>> faqItems = [
    {
      'question': 'Comment prendre un rendez-vous ?',
      'answer': 'Pour prendre un rendez-vous, recherchez d\'abord un service qui vous intéresse, puis cliquez sur "Prendre rendez-vous". Sélectionnez ensuite une date et une heure disponibles, et confirmez votre réservation.'
    },
    {
      'question': 'Comment annuler un rendez-vous ?',
      'answer': 'Pour annuler un rendez-vous, accédez à la section "Mes rendez-vous", sélectionnez le rendez-vous que vous souhaitez annuler, puis cliquez sur le bouton "Annuler". Veuillez noter que certains prestataires peuvent avoir des politiques d\'annulation spécifiques.'
    },
    {
      'question': 'Comment modifier mon profil ?',
      'answer': 'Pour modifier votre profil, accédez à l\'écran de profil en cliquant sur l\'icône de profil dans le menu principal. Vous pourrez alors modifier vos informations personnelles, votre photo de profil et vos préférences.'
    },
    {
      'question': 'Les paiements sont-ils sécurisés ?',
      'answer': 'Oui, tous les paiements effectués via notre application sont sécurisés. Nous utilisons des technologies de cryptage avancées pour protéger vos informations financières.'
    },
    {
      'question': 'Comment contacter le support client ?',
      'answer': 'Vous pouvez contacter notre équipe de support client via l\'écran "Contact" de l\'application, ou en envoyant un email à support@flexbookrdv.com. Nous sommes disponibles 7j/7 pour répondre à vos questions.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foire Aux Questions'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: faqItems.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                faqItems[index]['question']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    faqItems[index]['answer']!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}