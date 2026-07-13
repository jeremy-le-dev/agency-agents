# Patrimoine — Agrégateur de comptes iOS

Application iOS native (SwiftUI) pour agréger vos comptes bancaires, épargne et investissements, avec widget d'accueil affichant le patrimoine total.

Inspirée de **Bankin** et **Finary** : interface claire, cartes épurées, solde total en évidence.

## Fonctionnalités

- **Dashboard** : patrimoine total, répartition par catégorie, vue par établissement
- **Comptes** : liste détaillée (courant, épargne, investissements, assurance vie)
- **Connexion Powens (PSD2)** : Crédit Agricole, Trade Republic, Amundi, Linxea
- **Face ID / Touch ID** : verrouillage au lancement et retour en arrière-plan
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
│   ├── Services/Powens/ # API client + webview PSD2
│   └── Views/Security/  # Face ID
├── PatrimoineWidget/    # Extension WidgetKit
├── Shared/              # Modèles partagés App Group
└── project.yml          # Config XcodeGen
```

- `PowensService` : authentification, webview connect, sync comptes
- `BiometricLockManager` : Face ID via LocalAuthentication
- `MockInstitutionConnector` : mode démo sans Powens
- `WidgetDataManager` : partage via App Group `group.com.patrimoine.app`

## Prérequis

- macOS avec Xcode 15+
- iOS 17+
- Compte [Powens Console](https://console.powens.com) (pour connexion réelle)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (recommandé)

## Installation

```bash
cd Patrimoine
./setup.sh
open Patrimoine.xcodeproj
```

## Configuration Powens

1. Créer un domaine et une application client sur [console.powens.com](https://console.powens.com)
2. Ajouter `patrimoine://powens/callback` dans les redirect URIs autorisées
3. Copier le fichier de config :

```bash
cp Patrimoine/PowensConfig.example.plist Patrimoine/PowensConfig.plist
```

4. Renseigner les clés :

| Clé | Description |
|---|---|
| `POWENS_DOMAIN` | Votre domaine Powens (ex: `monapp`) |
| `POWENS_CLIENT_ID` | ID de l'application client |
| `POWENS_CLIENT_SECRET` | Secret client (dev uniquement) |
| `POWENS_REDIRECT_URI` | `patrimoine://powens/callback` |
| `POWENS_BACKEND_TOKEN_URL` | URL backend pour init sécurisé (prod) |

> **Production** : ne jamais embarquer le `client_secret` dans l'app. Utilisez `POWENS_BACKEND_TOKEN_URL` pour générer le token côté serveur.

### Flux de connexion

1. L'utilisateur appuie sur « Connecter » → webview Powens (ASWebAuthenticationSession)
2. Authentification bancaire PSD2 dans la webview
3. Callback `patrimoine://powens/callback?connection_id=…`
4. Récupération des comptes via `GET /users/me/accounts`
5. Token stocké dans le Keychain iOS

## Face ID

Activé par défaut. L'app se verrouille :
- au lancement
- au retour depuis l'arrière-plan

Désactivable dans **Profil → Sécurité**.

## Analyses

Onglet **Analyses** avec Swift Charts :

| Graphique | Contenu |
|---|---|
| Progression épargne | Courbe sur 12 mois (Livret A, LDDS, assurance vie) |
| Évolution patrimoine | Total, épargne, investissements |
| Revenus vs dépenses | Barres mensuelles |
| Dépenses par catégorie | Donut + détail (alimentation, logement, etc.) |
| Opérations récentes | Liste des dernières transactions |

Filtres : ce mois / 3 mois / 6 mois.

Les transactions proviennent de Powens si connecté, sinon données de démo sur les comptes courants.

## Widget

1. Lancer l'app au moins une fois
2. Appui long sur l'écran d'accueil → « + » → « Patrimoine »
3. Choisir la taille (petit, moyen, grand)

## Mode démo

Sans `PowensConfig.plist`, l'app utilise des données simulées.

## Licence

MIT
