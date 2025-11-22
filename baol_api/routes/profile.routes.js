const express = require ('express');
const router = express.Router ();
const {query} = require ('../config/database');
const fs = require ('fs').promises;
const path = require ('path');

/**
 * GET /api/profile/share/:userId
 * Génère une page HTML avec Open Graph pour le partage de profil
 */
router.get ('/share/:userId', async (req, res) => {
  try {
    const {userId} = req.params;

    // Récupérer les données du profil
    const profileQuery = `
      SELECT 
        id,
        name,
        email,
        photo_url,
        address,
        bio,
        phone
      FROM profiles
      WHERE id = $1
    `;

    const profileResult = await query (profileQuery, [userId]);

    if (profileResult.rows.length === 0) {
      return res.status (404).send (`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Profil non trouvé - SAME</title>
          <meta charset="UTF-8">
        </head>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
          <h1>😕 Profil non trouvé</h1>
          <p>Ce profil n'existe pas ou a été supprimé.</p>
          <a href="/" style="color: #4CAF50;">Retour à l'accueil</a>
        </body>
        </html>
      `);
    }

    const profile = profileResult.rows[0];

    // Récupérer le nombre d'équipements
    const equipmentQuery = `
      SELECT COUNT(*) as count
      FROM equipment
      WHERE provider_id = $1
    `;
    const equipmentResult = await query (equipmentQuery, [userId]);
    const equipmentCount = equipmentResult.rows[0].count || 0;

    // Récupérer les statistiques (note moyenne et nombre d'avis)
    // Pour l'instant, valeurs par défaut
    const rating = '4.5';
    const reviewsCount = '0';

    // Charger le template HTML
    const templatePath = path.join (
      __dirname,
      '../views/profile_template.html'
    );
    let htmlTemplate = await fs.readFile (templatePath, 'utf-8');

    // Préparer les données
    const baseUrl = process.env.API_URL || 'http://localhost:3000';
    const appLogo = `${baseUrl}/logo.jpg`;
    const userPhoto =
      profile.photo_url ||
      `https://ui-avatars.com/api/?name=${encodeURIComponent (profile.name)}&size=300&background=4CAF50&color=fff`;
    const profileUrl = `${baseUrl}/api/profile/share/${userId}`;
    const appDownloadLink = process.env.APP_DOWNLOAD_LINK || '#';

    // Description par défaut si pas de bio
    const userDescription =
      profile.bio ||
      `Membre de SAME, plateforme de location de matériel agricole. ${equipmentCount} équipement(s) disponible(s) à la location.`;

    // Remplacer les variables dans le template
    const replacements = {
      '{{userName}}': escapeHtml (profile.name || 'Utilisateur'),
      '{{userEmail}}': escapeHtml (profile.email || ''),
      '{{userPhoto}}': userPhoto,
      '{{userLocation}}': escapeHtml (profile.address || ''),
      '{{userDescription}}': escapeHtml (userDescription),
      '{{equipmentCount}}': equipmentCount,
      '{{rating}}': rating,
      '{{reviewsCount}}': reviewsCount,
      '{{appLogo}}': appLogo,
      '{{profileUrl}}': profileUrl,
      '{{appDownloadLink}}': appDownloadLink,
    };

    // Appliquer les remplacements
    let html = htmlTemplate;
    for (const [key, value] of Object.entries (replacements)) {
      html = html.split (key).join (value);
    }

    // Gérer les conditions Handlebars simplifiées
    if (!profile.address) {
      html = html.replace (/{{#if userLocation}}[\s\S]*?{{\/if}}/g, '');
    } else {
      html = html
        .replace (/{{#if userLocation}}/g, '')
        .replace (/{{\/if}}/g, '');
    }

    if (!profile.bio && equipmentCount === 0) {
      html = html.replace (/{{#if userDescription}}[\s\S]*?{{\/if}}/g, '');
    } else {
      html = html
        .replace (/{{#if userDescription}}/g, '')
        .replace (/{{\/if}}/g, '');
    }

    // Envoyer la page HTML
    res.setHeader ('Content-Type', 'text/html; charset=utf-8');
    res.send (html);
  } catch (error) {
    console.error ('Erreur lors de la génération du profil partagé:', error);
    res.status (500).send (`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Erreur - SAME</title>
        <meta charset="UTF-8">
      </head>
      <body style="font-family: Arial; text-align: center; padding: 50px;">
        <h1>❌ Erreur</h1>
        <p>Une erreur est survenue lors du chargement du profil.</p>
        <a href="/" style="color: #4CAF50;">Retour à l'accueil</a>
      </body>
      </html>
    `);
  }
});

/**
 * Échappe les caractères HTML pour éviter les injections XSS
 */
function escapeHtml (text) {
  if (!text) return '';
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  };
  return text.toString ().replace (/[&<>"']/g, m => map[m]);
}

module.exports = router;
