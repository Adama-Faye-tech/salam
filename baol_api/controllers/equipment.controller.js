const { query } = require('../config/database');
const { getFileUrl } = require('../middleware/upload');

/**
 * Obtenir tous les équipements avec filtres optionnels
 */
const getAllEquipment = async (req, res) => {
  try {
    const { category, minPrice, maxPrice, search, providerId, latitude, longitude, maxDistance } = req.query;

    let queryText = `
      SELECT e.*, u.name as provider_name, u.phone as provider_phone
    `;
    
    // Ajouter le calcul de distance si latitude/longitude fournis
    if (latitude && longitude) {
      queryText += `,
        (6371 * acos(
          cos(radians($${1})) * 
          cos(radians(e.latitude)) * 
          cos(radians(e.longitude) - radians($${2})) + 
          sin(radians($${1})) * 
          sin(radians(e.latitude))
        )) as distance
      `;
    }
    
    queryText += `
      FROM equipment e
      LEFT JOIN users u ON e.provider_id = u.id
      WHERE 1=1
    `;
    
    const queryParams = [];
    let paramIndex = 1;
    
    // Si on filtre par distance, ajouter les paramètres de position
    if (latitude && longitude) {
      queryParams.push(parseFloat(latitude), parseFloat(longitude));
      paramIndex += 2;
    }

    // Filtrer par catégorie
    if (category) {
      queryText += ` AND e.category = $${paramIndex++}`;
      queryParams.push(category);
    }

    // Filtrer par prix minimum
    if (minPrice) {
      queryText += ` AND e.price_per_day >= $${paramIndex++}`;
      queryParams.push(parseFloat(minPrice));
    }

    // Filtrer par prix maximum
    if (maxPrice) {
      queryText += ` AND e.price_per_day <= $${paramIndex++}`;
      queryParams.push(parseFloat(maxPrice));
    }

    // Recherche par nom ou description
    if (search) {
      queryText += ` AND (e.name ILIKE $${paramIndex++} OR e.description ILIKE $${paramIndex})`;
      queryParams.push(`%${search}%`, `%${search}%`);
      paramIndex++;
    }

    // Filtrer par prestataire
    if (providerId) {
      queryText += ` AND e.provider_id = $${paramIndex++}`;
      queryParams.push(providerId);
    }
    
    // Filtrer par équipements qui ont des coordonnées GPS (si tri par distance)
    if (latitude && longitude) {
      queryText += ` AND e.latitude IS NOT NULL AND e.longitude IS NOT NULL`;
      
      // Filtrer par distance maximale si spécifiée
      if (maxDistance) {
        queryText += ` HAVING distance <= $${paramIndex++}`;
        queryParams.push(parseFloat(maxDistance));
      }
    }

    // Tri par distance si coordonnées fournies, sinon par date
    queryText += latitude && longitude 
      ? ' ORDER BY distance ASC' 
      : ' ORDER BY e.created_at DESC';

    const result = await query(queryText, queryParams);

    // Ajouter l'URL complète pour les images
    const equipments = result.rows.map(equipment => ({
      ...equipment,
      imageUrl: equipment.image_url ? getFileUrl(equipment.image_url) : null,
    }));

    res.status(200).json({
      success: true,
      count: equipments.length,
      data: equipments,
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des équipements:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des équipements',
      error: error.message,
    });
  }
};

/**
 * Obtenir un équipement par ID
 */
const getEquipmentById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT e.*, u.name as provider_name, u.phone as provider_phone, u.email as provider_email
       FROM equipment e
       LEFT JOIN users u ON e.provider_id = u.id
       WHERE e.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Équipement non trouvé',
      });
    }

    const equipment = result.rows[0];
    equipment.imageUrl = equipment.image_url ? getFileUrl(equipment.image_url) : null;

    res.status(200).json({
      success: true,
      data: equipment,
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'équipement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de l\'équipement',
      error: error.message,
    });
  }
};

/**
 * Créer un nouvel équipement (prestataire uniquement)
 */
const createEquipment = async (req, res) => {
  try {
    const providerId = req.user.id;
    const { 
      name, description, type, category, 
      pricePerHour, pricePerDay, 
      year, model, brand,
      photos, videos,
      location, latitude, longitude,
      interventionZone, technicalSpecs
    } = req.body;

    // Validation des champs requis
    if (!name || !category || !pricePerDay) {
      return res.status(400).json({
        success: false,
        message: 'Nom, catégorie et prix/jour sont requis',
      });
    }

    const result = await query(
      `INSERT INTO equipment (
        name, description, type, category, 
        price_per_hour, price_per_day, 
        year, model, brand,
        photos, videos,
        location, latitude, longitude,
        intervention_zone, technical_specs,
        provider_id, available, created_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, true, NOW())
      RETURNING *`,
      [
        name, description, type || 'materiel', category,
        pricePerHour ? parseFloat(pricePerHour) : 0, parseFloat(pricePerDay),
        year, model, brand,
        photos ? JSON.stringify(photos) : '[]', 
        videos ? JSON.stringify(videos) : '[]',
        location, latitude ? parseFloat(latitude) : null, longitude ? parseFloat(longitude) : null,
        interventionZone, technicalSpecs ? JSON.stringify(technicalSpecs) : null,
        providerId
      ]
    );

    const equipment = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Équipement créé avec succès',
      data: equipment,
    });
  } catch (error) {
    console.error('Erreur lors de la création de l\'équipement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de l\'équipement',
      error: error.message,
    });
  }
};

/**
 * Mettre à jour un équipement
 */
const updateEquipment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { name, description, category, pricePerDay, location, imageUrl, available } = req.body;

    // Vérifier que l'équipement appartient à l'utilisateur
    const checkResult = await query(
      'SELECT provider_id FROM equipment WHERE id = $1',
      [id]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Équipement non trouvé',
      });
    }

    if (checkResult.rows[0].provider_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas autorisé à modifier cet équipement',
      });
    }

    // Récupérer tous les champs possibles
    const { 
      type, pricePerHour, year, model, brand,
      photos, videos, latitude, longitude,
      interventionZone, technicalSpecs
    } = req.body;

    // Construire la requête de mise à jour dynamiquement
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (name) {
      updates.push(`name = $${paramIndex++}`);
      values.push(name);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      values.push(description);
    }
    if (type) {
      updates.push(`type = $${paramIndex++}`);
      values.push(type);
    }
    if (category) {
      updates.push(`category = $${paramIndex++}`);
      values.push(category);
    }
    if (pricePerHour !== undefined) {
      updates.push(`price_per_hour = $${paramIndex++}`);
      values.push(parseFloat(pricePerHour));
    }
    if (pricePerDay) {
      updates.push(`price_per_day = $${paramIndex++}`);
      values.push(parseFloat(pricePerDay));
    }
    if (year) {
      updates.push(`year = $${paramIndex++}`);
      values.push(year);
    }
    if (model !== undefined) {
      updates.push(`model = $${paramIndex++}`);
      values.push(model);
    }
    if (brand !== undefined) {
      updates.push(`brand = $${paramIndex++}`);
      values.push(brand);
    }
    if (photos !== undefined) {
      updates.push(`photos = $${paramIndex++}`);
      values.push(JSON.stringify(photos));
    }
    if (videos !== undefined) {
      updates.push(`videos = $${paramIndex++}`);
      values.push(JSON.stringify(videos));
    }
    if (location !== undefined) {
      updates.push(`location = $${paramIndex++}`);
      values.push(location);
    }
    if (latitude !== undefined) {
      updates.push(`latitude = $${paramIndex++}`);
      values.push(latitude ? parseFloat(latitude) : null);
    }
    if (longitude !== undefined) {
      updates.push(`longitude = $${paramIndex++}`);
      values.push(longitude ? parseFloat(longitude) : null);
    }
    if (interventionZone !== undefined) {
      updates.push(`intervention_zone = $${paramIndex++}`);
      values.push(interventionZone);
    }
    if (technicalSpecs !== undefined) {
      updates.push(`technical_specs = $${paramIndex++}`);
      values.push(JSON.stringify(technicalSpecs));
    }
    if (imageUrl !== undefined) {
      updates.push(`image_url = $${paramIndex++}`);
      values.push(imageUrl);
    }
    if (available !== undefined) {
      updates.push(`available = $${paramIndex++}`);
      values.push(available);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Aucune donnée à mettre à jour',
      });
    }

    values.push(id);

    const result = await query(
      `UPDATE equipment SET ${updates.join(', ')} WHERE id = $${paramIndex}
       RETURNING *`,
      values
    );

    const equipment = result.rows[0];
    equipment.imageUrl = equipment.image_url ? getFileUrl(equipment.image_url) : null;

    res.status(200).json({
      success: true,
      message: 'Équipement mis à jour avec succès',
      data: equipment,
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour de l\'équipement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour de l\'équipement',
      error: error.message,
    });
  }
};

/**
 * Supprimer un équipement
 */
const deleteEquipment = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Vérifier que l'équipement appartient à l'utilisateur
    const checkResult = await query(
      'SELECT provider_id FROM equipment WHERE id = $1',
      [id]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Équipement non trouvé',
      });
    }

    if (checkResult.rows[0].provider_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'êtes pas autorisé à supprimer cet équipement',
      });
    }

    await query('DELETE FROM equipment WHERE id = $1', [id]);

    res.status(200).json({
      success: true,
      message: 'Équipement supprimé avec succès',
    });
  } catch (error) {
    console.error('Erreur lors de la suppression de l\'équipement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de l\'équipement',
      error: error.message,
    });
  }
};

module.exports = {
  getAllEquipment,
  getEquipmentById,
  createEquipment,
  updateEquipment,
  deleteEquipment,
};
