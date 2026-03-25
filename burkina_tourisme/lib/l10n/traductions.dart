class Traductions {
  static const Map<String, Map<String, String>> _textes = {
    'fr': {
      // Navigation
      'accueil': 'Accueil',
      'favoris': 'Favoris',
      'profil': 'Profil',

      // Home
      'decouvrez': 'Découvrez\nle Burkina Faso',
      'slogan': 'Explorez les trésors du pays des hommes intègres',
      'rechercher': 'Rechercher...',
      'lieux_populaires': 'Lieux populaires',
      'attractions': 'Attractions',
      'restaurants': 'Restaurants',
      'hebergements': 'Hébergements',
      'culture': 'Culture & Événements',

      // Favoris
      'aucun_favori': 'Aucun favori pour l\'instant',
      'ajouter_favori': 'Ajoutez des lieux en appuyant sur ❤️',
      'ajoute_favori': '❤️ Ajouté aux favoris',
      'retire_favori': '💔 Retiré des favoris',

      // Détail
      'detail': 'Détail Attraction',
      'adresse': 'Adresse',
      'contact': 'Contact',
      'appeler': 'Appeler',
      'voir_carte': 'Voir sur la carte',

      // Recherche
      'recherche': 'Recherche',
      'recherche_hint': 'Rechercher un lieu, une ville...',
      'aucun_resultat': 'Aucun résultat trouvé',
      'recherche_prompt': 'Recherchez un lieu ou une ville',

      // Profil
      'voyageur': 'Voyageur Burkinabè',
      'categories': 'Catégories',
      'lieux': 'Lieux',
      'a_propos': 'À propos de l\'app',
      'langue': 'Langue',
      'notifications': 'Notifications',
      'partager': 'Partager l\'application',
      'noter': 'Noter l\'application',
      'confidentialite': 'Politique de confidentialité',
      'theme': 'Thème sombre',
      'fermer': 'Fermer',
      'a_propos_contenu':
          'Application de découverte touristique du Burkina Faso.\n\n'
          'Explorez les merveilles du pays des hommes intègres : '
          'attractions naturelles, restaurants, hébergements et événements culturels.\n\n'
          'Version 1.0.0',
    },
    'en': {
      // Navigation
      'accueil': 'Home',
      'favoris': 'Favorites',
      'profil': 'Profile',

      // Home
      'decouvrez': 'Discover\nBurkina Faso',
      'slogan': 'Explore the treasures of the land of upright people',
      'rechercher': 'Search...',
      'lieux_populaires': 'Popular Places',
      'attractions': 'Attractions',
      'restaurants': 'Restaurants',
      'hebergements': 'Accommodations',
      'culture': 'Culture & Events',

      // Favoris
      'aucun_favori': 'No favorites yet',
      'ajouter_favori': 'Add places by tapping ❤️',
      'ajoute_favori': '❤️ Added to favorites',
      'retire_favori': '💔 Removed from favorites',

      // Détail
      'detail': 'Attraction Detail',
      'adresse': 'Address',
      'contact': 'Contact',
      'appeler': 'Call',
      'voir_carte': 'View on map',

      // Recherche
      'recherche': 'Search',
      'recherche_hint': 'Search a place, a city...',
      'aucun_resultat': 'No results found',
      'recherche_prompt': 'Search for a place or city',

      // Profil
      'voyageur': 'Burkinabe Traveler',
      'categories': 'Categories',
      'lieux': 'Places',
      'a_propos': 'About the app',
      'langue': 'Language',
      'notifications': 'Notifications',
      'partager': 'Share the app',
      'noter': 'Rate the app',
      'confidentialite': 'Privacy policy',
      'theme': 'Dark theme',
      'fermer': 'Close',
      'a_propos_contenu':
          'Tourist discovery application for Burkina Faso.\n\n'
          'Explore the wonders of the land of upright people: '
          'natural attractions, restaurants, accommodations and cultural events.\n\n'
          'Version 1.0.0',
    },
  };

  static String t(String key, String langue) {
    return _textes[langue]?[key] ?? key;
  }
}