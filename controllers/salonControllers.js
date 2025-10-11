const {query} = require('../database');

exports.getAllSalons = async (req, res) => {
    try {
        const salons = await query('SELECT * FROM salons');
        res.json(salons);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch salons' });
    }
};