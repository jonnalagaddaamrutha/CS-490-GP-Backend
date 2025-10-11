const express=require('express');
const router=express.Router();
const db=require('../database');
const salonController=require('../controllers/salonControllers');

router.get('/', salonController.getAllSalons);
module.exports=router;