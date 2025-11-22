const express = require ('express');
const router = express.Router ();
const {authenticate} = require ('../middleware/auth');

/**
 * @route   POST /api/promo/verify
 * @desc    Vérifier un code promo
 * @access  Private
 */
router.post ('/verify', authenticate, (req, res) => {
  const {code} = req.body;

  if (!code) {
    return res.status (400).json ({
      success: false,
      message: 'Code promo requis',
    });
  }

  // Liste des codes promo valides (dans une vraie app, utiliser une table DB)
  const promoCodes = {
    SAME2026: {
      discount: 0.10,
      type: 'percentage',
      description: '10% de réduction',
    },
    BIENVENUE: {
      discount: 0.15,
      type: 'percentage',
      description: '15% de réduction',
    },
    FIRST20: {discount: 20, type: 'fixed', description: '20€ de réduction'},
    AGRICOLE50: {discount: 50, type: 'fixed', description: '50€ de réduction'},
  };

  const promoCode = code.toUpperCase ();
  const promo = promoCodes[promoCode];

  if (!promo) {
    return res.status (404).json ({
      success: false,
      message: 'Code promo invalide',
    });
  }

  return res.status (200).json ({
    success: true,
    message: 'Code promo valide',
    promo: {
      code: promoCode,
      discount: promo.discount,
      type: promo.type,
      description: promo.description,
    },
  });
});

module.exports = router;
