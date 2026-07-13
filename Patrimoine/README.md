# Patrimoine — Agrégateur de comptes iOS

Application iOS native (SwiftUI) pour agréger vos comptes bancaires, épargne et investissements, avec widget d'accueil affichant le patrimoine total.

Inspirée de **Bankin** et **Finary** : interface claire, cartes épurées, solde total en évidence.

## Fonctionnalités

- **Dashboard** : patrimoine total, répartition par catégorie, vue par établissement
- **Comptes** : liste détaillée (courant, épargne, investissements, assurance vie)
- **Connexion** : Crédit Agricole, Trade Republic, Amundi, Linxea
- **Widget iOS** : petit, moyen et grand format
- **Pull-to-refresh** et synchronisation
- **Masquage du solde** (bouton œil)

## Établissements supportés

| Établissement | Type | Catégorie |
|---|---|---|
| Crédit Agricole | Banque | Comptes courants, épargne |
| Trade Republic | Courtier | Investissements |
| Amundi | Gestion d'actifs | PEA, assurance vie |
| Linxea | Assurance vie | Contrats Spirit, Avenir |

## Architecture

```
Patrimoine/
├── Patrimoine/          # App principale SwiftUI
├── PatrimoineWidget/    # Extension WidgetKit
├── Shared/              # Modèles partagés App Group
└── project.yml          # Config XcodeGen
```

- `InstitutionConnector` : protocole d'agrégation par établissement
- `MockInstitutionConnector` : données de démo (MVP)
- `PSD2AggregatorConnector` : point d'extension pour Powens / Budget Insight
- `WidgetDataManager` : partage via App Group `group.com.patrimoine.app`

## Prérequis

- macOS avec Xcode 15+
- iOS 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (optionnel mais recommandé)

## Installation

```bash
cd Patrimoine

# Générer le projet Xcode
brew install xcodegen   # si nécessaire
xcodegen generate

# Ouvrir dans Xcode
open Patrimoine.xcodeproj
```

### Configuration manuelle (sans XcodeGen)

1. Créer un projet iOS App « Patrimoine » dans Xcode
2. Ajouter les sources de `Patrimoine/` et `Shared/`
3. Créer une Widget Extension « PatrimoineWidget »
4. Configurer l'App Group `group.com.patrimoine.app` sur les deux cibles
5. Copier les fichiers `.entitlements`

### Widget

1. Lancer l'app au moins une fois pour initialiser les données
2. Appui long sur l'écran d'accueil → « + » → chercher « Patrimoine »
3. Choisir la taille (petit, moyen, grand)

## Connexion bancaire réelle (production)

Les connecteurs mock simulent la synchronisation. Pour une connexion PSD2 réelle :

1. S'inscrire chez un agrégateur ([Powens](https://www.powens.com), Budget Insight, etc.)
2. Implémenter `PSD2AggregatorConnector` avec l'API choisie
3. Remplacer `MockInstitutionConnector` dans `AggregationService.init()`

## Captures d'écran (écrans)

| Accueil | Comptes | Ajouter | Widget |
|---|---|---|---|
| Solde total + répartition | Liste par catégorie | Connexion établissements | Solde en un coup d'œil |

## Licence

MIT
