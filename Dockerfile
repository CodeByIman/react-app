# Étape 1 : Utiliser une image de base Node.js (version 18 pour correspondre à React 18)
FROM node:18-alpine AS build

# Étape 2 : Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Étape 3 : Copier les fichiers package.json et package-lock.json
COPY package*.json ./

# Étape 4 : Installer les dépendances (y compris les devDependencies pour Tailwind CSS)
RUN npm install

# Étape 5 : Copier le reste des fichiers de l'application
COPY . .

# Étape 6 : Construire l'application React (cela exécutera "npm run build")
RUN npm run build

# Étape 7 : Utiliser une image Nginx pour servir l'application
FROM nginx:alpine

# Étape 8 : Copier les fichiers construits dans le répertoire Nginx
COPY --from=build /app/build /usr/share/nginx/html

# Étape 9 : Exposer le port 80
EXPOSE 80

# Étape 10 : Démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]