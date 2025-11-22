const bcrypt = require ('bcrypt');
const {query} = require ('../config/database');
const {generateToken} = require ('../middleware/auth');

/**
 * Inscription d'un nouvel utilisateur
 */
const register = async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      phone,
      address,
      location,
      userType,
      description,
    } = req.body;

    // Validation des champs requis
    if (!name || !email || !password) {
      return res.status (400).json ({
        success: false,
        message: 'Nom, email et mot de passe sont requis',
      });
    }

    // Vérifier si l'email existe déjà
    const existingUser = await query ('SELECT id FROM users WHERE email = $1', [
      email,
    ]);

    if (existingUser.rows.length > 0) {
      return res.status (409).json ({
        success: false,
        message: 'Cet email est déjà utilisé',
      });
    }

    // Hasher le mot de passe
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash (password, saltRounds);

    // Insérer l'utilisateur dans la base de données
    const result = await query (
      `INSERT INTO users (name, email, password_hash, phone, address, location, user_type, description, role, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
       RETURNING id, name, email, phone, address, location, photo_url, user_type, description, role, created_at`,
      [
        name,
        email,
        hashedPassword,
        phone || null,
        address || null,
        location || null,
        userType || 'farmer',
        description || null,
        'client',
      ]
    );

    const user = result.rows[0];

    // Générer le token JWT
    const token = generateToken ({
      userId: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    });

    res.status (201).json ({
      success: true,
      message: 'Utilisateur créé avec succès',
      data: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          address: user.address,
          location: user.location,
          photoUrl: user.photo_url,
          userType: user.user_type,
          description: user.description,
          role: user.role,
          createdAt: user.created_at,
        },
        token,
      },
    });
  } catch (error) {
    console.error ("Erreur lors de l'inscription:", error);
    res.status (500).json ({
      success: false,
      message: "Erreur lors de l'inscription",
      error: error.message,
    });
  }
};

/**
 * Connexion d'un utilisateur
 */
const login = async (req, res) => {
  try {
    const {email, password} = req.body;

    // Validation des champs requis
    if (!email || !password) {
      return res.status (400).json ({
        success: false,
        message: 'Email et mot de passe sont requis',
      });
    }

    // Récupérer l'utilisateur depuis la base de données
    const result = await query (
      'SELECT id, name, email, password_hash, phone, address, location, photo_url, user_type, description, role, created_at FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status (401).json ({
        success: false,
        message: 'Email ou mot de passe incorrect',
      });
    }

    const user = result.rows[0];

    // Vérifier le mot de passe
    const isPasswordValid = await bcrypt.compare (password, user.password_hash);

    if (!isPasswordValid) {
      return res.status (401).json ({
        success: false,
        message: 'Email ou mot de passe incorrect',
      });
    }

    // Générer le token JWT
    const token = generateToken ({
      userId: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    });

    res.status (200).json ({
      success: true,
      message: 'Connexion réussie',
      data: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          address: user.address,
          location: user.location,
          photoUrl: user.photo_url,
          userType: user.user_type,
          description: user.description,
          role: user.role,
          createdAt: user.created_at,
        },
        token,
      },
    });
  } catch (error) {
    console.error ('Erreur lors de la connexion:', error);
    res.status (500).json ({
      success: false,
      message: 'Erreur lors de la connexion',
      error: error.message,
    });
  }
};

/**
 * Obtenir le profil de l'utilisateur connecté
 */
const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query (
      'SELECT id, name, email, phone, address, location, photo_url, user_type, description, role, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status (404).json ({
        success: false,
        message: 'Utilisateur non trouvé',
      });
    }

    const user = result.rows[0];

    res.status (200).json ({
      success: true,
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        address: user.address,
        location: user.location,
        photoUrl: user.photo_url,
        userType: user.user_type,
        description: user.description,
        role: user.role,
        createdAt: user.created_at,
      },
    });
  } catch (error) {
    console.error ('Erreur lors de la récupération du profil:', error);
    res.status (500).json ({
      success: false,
      message: 'Erreur lors de la récupération du profil',
      error: error.message,
    });
  }
};

/**
 * Mettre à jour le profil de l'utilisateur
 */
const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      name,
      phone,
      address,
      location,
      photoUrl,
      description,
      userType,
    } = req.body;

    // Construire la requête de mise à jour dynamiquement
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (name) {
      updates.push (`name = $${paramIndex++}`);
      values.push (name);
    }
    if (phone !== undefined) {
      updates.push (`phone = $${paramIndex++}`);
      values.push (phone);
    }
    if (address !== undefined) {
      updates.push (`address = $${paramIndex++}`);
      values.push (address);
    }
    if (location !== undefined) {
      updates.push (`location = $${paramIndex++}`);
      values.push (location);
    }
    if (photoUrl !== undefined) {
      updates.push (`photo_url = $${paramIndex++}`);
      values.push (photoUrl);
    }
    if (description !== undefined) {
      updates.push (`description = $${paramIndex++}`);
      values.push (description);
    }
    if (userType !== undefined) {
      updates.push (`user_type = $${paramIndex++}`);
      values.push (userType);
    }

    if (updates.length === 0) {
      return res.status (400).json ({
        success: false,
        message: 'Aucune donnée à mettre à jour',
      });
    }

    values.push (userId);

    const result = await query (
      `UPDATE users SET ${updates.join (', ')} WHERE id = $${paramIndex}
       RETURNING id, name, email, phone, address, location, photo_url, user_type, description, role, created_at`,
      values
    );

    const user = result.rows[0];

    res.status (200).json ({
      success: true,
      message: 'Profil mis à jour avec succès',
      data: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          address: user.address,
          location: user.location,
          photoUrl: user.photo_url,
          userType: user.user_type,
          description: user.description,
          role: user.role,
          createdAt: user.created_at,
        },
      },
    });
  } catch (error) {
    console.error ('Erreur lors de la mise à jour du profil:', error);
    res.status (500).json ({
      success: false,
      message: 'Erreur lors de la mise à jour du profil',
      error: error.message,
    });
  }
};

/**
 * Changer le mot de passe
 */
const changePassword = async (req, res) => {
  try {
    const userId = req.user.id;
    const {currentPassword, newPassword} = req.body;

    if (!currentPassword || !newPassword) {
      return res.status (400).json ({
        success: false,
        message: 'Mot de passe actuel et nouveau mot de passe sont requis',
      });
    }

    // Récupérer le hash actuel
    const result = await query (
      'SELECT password_hash FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status (404).json ({
        success: false,
        message: 'Utilisateur non trouvé',
      });
    }

    const user = result.rows[0];

    // Vérifier le mot de passe actuel
    const isPasswordValid = await bcrypt.compare (
      currentPassword,
      user.password_hash
    );

    if (!isPasswordValid) {
      return res.status (401).json ({
        success: false,
        message: 'Mot de passe actuel incorrect',
      });
    }

    // Hasher le nouveau mot de passe
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash (newPassword, saltRounds);

    // Mettre à jour le mot de passe
    await query ('UPDATE users SET password_hash = $1 WHERE id = $2', [
      hashedPassword,
      userId,
    ]);

    res.status (200).json ({
      success: true,
      message: 'Mot de passe changé avec succès',
    });
  } catch (error) {
    console.error ('Erreur lors du changement de mot de passe:', error);
    res.status (500).json ({
      success: false,
      message: 'Erreur lors du changement de mot de passe',
      error: error.message,
    });
  }
};

/**
 * Supprimer le compte utilisateur
 */
const deleteAccount = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Supprimer toutes les données liées à l'utilisateur
    // (dans une vraie app, utiliser des transactions ou soft delete)

    // Supprimer les équipements de l'utilisateur
    await query ('DELETE FROM equipment WHERE provider_id = $1', [userId]);

    // Supprimer les commandes
    await query ('DELETE FROM orders WHERE user_id = $1 OR provider_id = $1', [
      userId,
    ]);

    // Supprimer les favoris
    await query ('DELETE FROM favorites WHERE user_id = $1', [userId]);

    // Supprimer les notifications
    await query ('DELETE FROM notifications WHERE user_id = $1', [userId]);

    // Supprimer les messages de chat
    await query (
      'DELETE FROM messages WHERE sender_id = $1 OR receiver_id = $1',
      [userId]
    );

    // Enfin, supprimer l'utilisateur
    await query ('DELETE FROM users WHERE id = $1', [userId]);

    res.status (200).json ({
      success: true,
      message: 'Compte supprimé avec succès',
    });
  } catch (error) {
    console.error ('Erreur lors de la suppression du compte:', error);
    res.status (500).json ({
      success: false,
      message: 'Erreur lors de la suppression du compte',
      error: error.message,
    });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword,
  deleteAccount,
};
