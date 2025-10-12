const {query} = require('../database');

//As a user, I want to browse available salons so that I can choose where to book 
exports.getAllSalons = async (req, res) => {
    if (!req.user) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    //free days sent by the user to filter salons
    const { freeDays } = req.query // e.g., ?freeDays=Monday,Tuesday
    const daysArray = freeDays ? freeDays.split(',') : [];
    try {
        const salons = await query(
            "select s.salon_id, sa.* from salon_platform.staff_availability sa join salon_platform.staff s  where sa.day_of_week IN ? and s.staff_id = sa.staff_id", [daysArray]);
        res.json(salons);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch salons' });
    }
};

exports.getStaffBySalonId = async (req, res) => {
    const salonId=req.params.salonId;
    try{
        const staff=await query('SELECT * FROM staff WHERE salon_id=?',[salonId]);
        res.json(staff);
    }
    catch(error){
        res.status(500).json({error:'Failed to fetch staff for the salon'});
    }
};
