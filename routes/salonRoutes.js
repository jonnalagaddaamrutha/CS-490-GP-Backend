const express=require('express');
import { verifyFirebaseToken } from "../middleware/firebaseAuth.js";
const router=express.Router();
const db=require('../database');
const salonController=require('../controllers/salonControllers');

router.get('/', verifyFirebaseToken, salonController.getAllSalons);
router.get('/:salonId/staff', verifyFirebaseToken, salonController.getStaffBySalonId);
module.exports=router;