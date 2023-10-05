# TP 6

![wordpress-logo](images/wordpress-logo.png)

**Saviez vous que [Wordpress](https://wordpress.com/fr/) est le constructeur de site internet le plus utilisé ?**
![wordpress_market](./images/wordpress_market_share.png)

-> 43% des sites internet ont été réalisés avec WordPress et 63% des blogs 🤯

Vous êtes la nouvelle / le nouveau DevOps Engineer d'une startup 👩‍💻👨‍💻
Vous avez pour objectif de configurer l'infrastructure sur GCP qui hébergera le site de l'entreprise 🌏.

Dans ce TP, l'objectif est de **déployer l'application Wordpress** sur Cloud Run en utilisant les outils et pratiques vus ensemble : git, Docker, Artifact Registry, Cloud Build et Infrastructure as Code (Terraform).

En bon ingénieur·e DevOps, nous allons découper le travail en  3 parties. Les 2 premières sont complètement indépendantes.

## Partie 1 : Infrastructure as Code

Afin d'avoir une configuration facile à maintenir pour le futur, on souhaite utiliser Terraform pour définir l'infrastructure nécessaire à Wordpress.

**💡 Créez les relations de dépendances entre les ressources pour les créer dans le bon ordre**

Nous allons créer les ressources suivantes à l'aide de Terraform :
- Les APIs nécessaires au bon fonctionnement du projet :
  - `cloudresourcemanager.googleapis.com`
  - `serviceusage.googleapis.com`
  - `artifactregistry.googleapis.com`
  - `sqladmin.googleapis.com`
  - `cloudbuild.googleapis.com`

- Dépôt Artifact Registry avec commme repository_id : `website-tools`

- Une base de données MySQL `wordpress` : l'instance de la base de donnée `main-instance` a été crée pendant le préparation du TP avec la commande `gcloud`

- un compte utilisateur de la base de données

1. Commencer par créer le bucket GCS (Google Cloud Storage) qui servira à stocker le state Terraform.
2. Définir les éléments de base nécessaires à la bonne exécution de terraform : utiliser l'exemple sur le [repo du cours](https://github.com/aballiet/DevOps-dauphine-public/tree/main/exemple/cloudbuild-terraform) pour vous aider
3. Afin de créer la base de données, utiliser la documentation [SQL Database](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) et enfin un [SQL User](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user)
   1. Pour `google_sql_database`, définir `name="wordpress"` et `instance="main-instance"`
   2. Pour `google_sql_user`, définissez le comme ceci :
      ```hcl
      resource "google_sql_user" "wordpress" {
         name     = "wordpress"
         instance = "main-instance"
         password = "ilovedevops"
      }
      ```
4. Lancer `terraform plan`, vérifier les changements puis appliquer les changements avec `terraform apply`
5. Vérifier que notre utilisateur existe bien : https://console.cloud.google.com/sql/instances/main-instance/users (veiller à bien séléctionner le projet GCP sur lequel vous avez déployé vos ressources)
```
Réponse: l'utilisateur existe bien sous le nom 'wordpress'
```
6. Rendez-vous sur https://console.cloud.google.com/sql/instances/main-instance/databases. Quelles sont les base de données présentes sur votre instance `main-instance` ? Quels sont les types ?
```
Réponse: 
information_schema 	utf8mb3_general_ci 	utf8mb3 	Système 	
	
mysql 	utf8mb3_general_ci 	utf8mb3 	Système 	
	
performance_schema 	utf8mb4_0900_ai_ci 	utf8mb4 	Système 	
	
sys 	utf8mb4_0900_ai_ci 	utf8mb4 	Système 	
	
wordpress 	utf8mb4_0900_ai_ci 	utf8mb4 	Utilisateur 	
```

## Partie 2 : Docker

Wordpress dispose d'une image Docker officielle disponible sur [DockerHub](https://hub.docker.com/_/wordpress)

1. Récupérer l'image sur votre machine (Cloud Shell)
```
Réponse: docker pull wordpress
(pour vérifier : docker images | grep wordpress.
résultat : wordpress    latest    8c0f37ccd87f   2 weeks ago   666MB)
```

2. Lancer l'image docker et ouvrez un shell à l'intérieur de votre container:
   1. Quel est le répertoire courant du container (WORKDIR) ?
   2. Que contient le fichier `index.php` ?

```
Réponse : docker run -d -p 8000:80 --name wordpress-conta
iner wordpress:latest
puis commande "pwd" = /var/www/html

puis commande "cat index.php" = "<?php
/**
 * Front to the WordPress application. This file doesn't do anything, but loads
 * wp-blog-header.php which does and tells WordPress to load the theme.
 *
 * @package WordPress
 */

/**
 * Tells WordPress to load the WordPress theme and output it.
 *
 * @var bool
 */
define( 'WP_USE_THEMES', true );

/** Loads the WordPress Environment and Template */
require __DIR__ . '/wp-blog-header.php';"

   ```

3. Supprimez le container puis relancez en un en spécifiant un port binding (une correspondance de port).

   1. Vous devez pouvoir communiquer avec le port par défaut de wordpress : **80** (choisissez un port entre 8000 et 9000 sur votre machine hôte => cloudshell)
```
docker ps pour récuperer l'id : 87c622282dc4
docker rm -f 87c622282dc4
docker run -d -p 8080:80 wordpress:latest
```

   2. Avec la commande `curl`, faites une requêtes depuis votre machine hôte à votre container wordpress. Quelle est la réponse ? (il n'y a pas piège, essayez sur un port non utilisé pour constater la différence)
```
curl http://localhost:8080
Il n'y a rien

pour vérifier : curl http://localhost:8081
message d'erreur. Alors l'instance wordpress est accessible sur le port 8080
```

   3. Afficher les logs de votre container après avoir fait quelques requêtes, que voyez vous ?

```
docker ps
resultat : CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS         PORTS                  NAMES
225e7b952b8a   wordpress:latest   "docker-entrypoint.s…"   6 minutes ago   Up 6 minutes   0.0.0.0:8080->80/tcp   thirsty_euler

puis : docker logs 225e7b952b8a

resultat:
WordPress not found in /var/www/html - copying now...
Complete! WordPress has been successfully copied to /var/www/html
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.18.0.2. Set the 'ServerName' directive globally to suppress this message
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.18.0.2. Set the 'ServerName' directive globally to suppress this message
[Thu Oct 05 09:18:36.522251 2023] [mpm_prefork:notice] [pid 1] AH00163: Apache/2.4.56 (Debian) PHP/8.0.30 configured -- resuming normal operations
[Thu Oct 05 09:18:36.522354 2023] [core:notice] [pid 1] AH00094: Command line: 'apache2 -D FOREGROUND'
172.18.0.1 - - [05/Oct/2023:09:20:14 +0000] "GET / HTTP/1.1" 302 235 "-" "curl/7.74.0"
172.18.0.1 - - [05/Oct/2023:09:21:43 +0000] "GET / HTTP/1.1" 302 235 "-" "curl/7.74.0"

```
   4. Utilisez l'aperçu web pour afficher le résultat du navigateur qui se connecte à votre container wordpress
      1. Utiliser la fonction `Aperçu sur le web`
        ![web_preview](images/wordpress_preview.png)
      2. Modifier le port si celui choisi n'est pas `8000`
      3. Une fenètre s'ouvre, que voyez vous ?
```
Réponse: 
Page de setup wordpress :

"
WordPress
Select a default language
Select a default language
"
```      

4. A partir de la documentation, remarquez les paramètres requis pour la configuration de la base de données.

```
wp-config.php :

DB_NAME
DB_USER
DB_PASSWORD
DB_HOST
DB_CHARSET
DB_COLLATE 
```

5. Dans la partie 1 du TP (si pas déjà fait), nous allons créer cette base de donnée. Dans cette partie 2 nous allons créer une image docker qui utilise des valeurs spécifiques de paramètres pour la base de données.
   1. Créer un Dockerfile
```
touch Dockerfile

contenu :
FROM wordpress:latest

ENV WORDPRESS_DB_HOST=0.0.0.0
ENV WORDPRESS_DB_USER=wordpress
ENV WORDPRESS_DB_PASSWORD=ilovedevops
ENV WORDPRESS_DB_NAME=wordpress



```   
   2. Spécifier les valeurs suivantes pour la base de données à l'aide de l'instruction `ENV` (voir [ici](https://stackoverflow.com/questions/57454581/define-environment-variable-in-dockerfile-or-docker-compose)):
        - `WORDPRESS_DB_USER=wordpress`
        - `WORDPRESS_DB_PASSWORD=ilovedevops`
        - `WORDPRESS_DB_NAME=wordpress`
        - `WORDPRESS_DB_HOST=0.0.0.0`
   3. Construire l'image docker.
```
docker build -t my-custom-wordpress:latest .

```
   4. Lancer une instance de l'image, ouvrez un shell. Vérifier le résultat de la commande `echo $WORDPRESS_DB_PASSWORD`

```
docker run -it --rm my-custom-wordpress:latest /bin/bash
echo $WORDPRESS_DB_PASSWORD
>ilovedevops
```

6. Pipeline d'Intégration Continue (CI):
   1. Créer un dépôt de type `DOCKER` sur artifact registry (si pas déjà fait, sinon utiliser celui appelé `website-tools`)
   2. Créer une configuration cloudbuild pour construire l'image docker et la publier sur le depôt Artifact Registry
```
   Réponse : 
   steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'us-central1-docker.pkg.dev/devops4-401021/website-tools/image-wordpress', '.' ]

images :
- 'us-central1-docker.pkg.dev/devops4-401021/website-tools/image-wordpress'
```
   3. Envoyer (`submit`) le job sur Cloud Build et vérifier que l'image a bien été créée
   ```
   gcloud builds submit --config cloudbuild.yaml .

   ```

## Partie 3 : Déployer Wordpress sur Cloud Run 🔥

Nous allons maintenant mettre les 2 parties précédentes ensemble.

Notre but, ne l'oublions pas est de déployer wordpress sur Cloud Run !

### Configurer l'adresse IP de la base MySQL utilisée par Wordpress

1. Rendez vous sur : https://console.cloud.google.com/sql/instances/main-instance/connections/summary?
   L'instance de base données dispose d'une `Adresse IP publique`. Nous allons nous servir de cette valeur pour configurer notre image docker Wordpress qui s'y connectera.

```
changer dockerFile : ENV WORDPRESS_DB_HOST=34.31.51.179

```

2. Reprendre le Dockerfile de la [Partie 2](#partie-2--docker) et le modifier pour que `WORDPRESS_DB_HOST` soit défini avec l'`Adresse IP publique` de notre instance de base de donnée.
3. Reconstruire notre image docker et la pousser sur notre Artifact Registry en utilisant cloud build

```
gcloud builds submit --config cloudbuild.yaml .

pour deployer : gcloud run deploy wordpress-service \
    --image=us-central1-docker.pkg.dev/devops4-401021/website-tools/my-custom-wordpress:latest \
    --platform managed \
    --region=us-central1 \
    --allow-unauthenticated

```

### Déployer notre image docker sur Cloud Run

1. Ajouter une ressource Cloud Run à votre code Terraform. Veiller à renseigner le bon tag de l'image docker que l'on vient de publier sur notre dépôt dans le champs `image` :

   ```hcl
   resource "google_cloud_run_service" "default" {
   name     = "serveur-wordpress"
   location = "us-central1"

   template {
      spec {
         containers {
         image = "us-docker.pkg.dev/cloudrun/container/hello"
         }
      }

      metadata {
         annotations = {
         "autoscaling.knative.dev/maxScale"      = "1000"
         "run.googleapis.com/cloudsql-instances" = "main-instance"
         "run.googleapis.com/client-name"        = "terraform"
         }
      }
   }

   traffic {
      percent         = 100
      latest_revision = true
   }
   }
   ```

   Afin d'autoriser tous les appareils à se connecter à notre Cloud Run, on définit les ressources :

   ```hcl
   data "google_iam_policy" "noauth" {
      binding {
         role = "roles/run.invoker"
         members = [
            "allUsers",
         ]
      }
   }

   resource "google_cloud_run_service_iam_policy" "noauth" {
      location    = google_cloud_run_service.default.location
      project     = google_cloud_run_service.default.project
      service     = google_cloud_run_service.default.name

      policy_data = data.google_iam_policy.noauth.policy_data
   }
   ```

   ☝️ Vous aurez besoin d'activer l'API : `run.googleapis.com` pour créer la ressource de type `google_cloud_run_service`. Faites en sorte que l'API soit activé avant de créer votre instance Cloud Run 😌

   Appliquer les changements sur votre projet gcp avec les commandes terraform puis rendez vous sur https://console.cloud.google.com/run pendant le déploiement.

2. Observer les journaux de Cloud Run (logs) sur : https://console.cloud.google.com/run/detail/us-central1/serveur-wordpress/logs.
   1. Véirifer la présence de l'entrée `No 'wp-config.php' found in /var/www/html, but 'WORDPRESS_...' variables supplied; copying 'wp-config-docker.php' (WORDPRESS_DB_HOST WORDPRESS_DB_PASSWORD WORDPRESS_DB_USER)`
   2. Au bout de 5 min, que se passe-t-il ? 🤯🤯🤯
   3. Regarder le resultat de votre commande `terraform apply` et observer les logs de Cloud Run
   4. Quelle est la raison de l'erreur ? Que faut-il changer dans les paramètre de notre ressource terraform `google_cloud_run_service` ?

3. A l'aide de la documentation terraform, d'internet ou de ChatGPT, ou même d'un certain TP 😌 faites en sorte que Cloud Run soit correctement configuré pour utiliser votre image Docker wordpress.

4. Autoriser toutes les adresses IP à se connecter à notre base MySQL (sous réserve d'avoir l'utilisateur et le mot de passe évidemment)
   1. Pour le faire, exécuter la commande
      ```bash
      gcloud sql instances patch main-instance \
      --authorized-networks=0.0.0.0/0
      ```

5. Accéder à notre Wordpress déployé 🚀
   1. Aller sur : https://console.cloud.google.com/run/detail/us-central1/serveur-wordpress/metrics?
   2. Cliquer sur l'URL de votre Cloud Run : similaire à https://serveur-wordpress-oreldffftq-uc.a.run.app
   3. Que voyez vous ? 🙈


## BONUS : Partie 4

1. Utiliser Cloud Build pour appliquer les changements d'infrastructure
2. Quelles critiques du TP pouvez vous faire ? Quels sont les éléments redondants de notre configuration ?
   1. Quels paramètres avons nous dû recopier plusieurs fois ?
   2. Comment pourrions nous faire pour ne pas avoir à les recopier ?
   3. Quels paramètres de la ressource Cloud Run peuvent être utilisés pour simplifier la gestion de notre application ?
   4. Créer une nouvelle ressource terraform de Cloud Run et appliquer lui les améliorations 😌
