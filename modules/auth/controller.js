const express = require('express');
const router = express.Router();
const pool = require('../../config/database');
const {firebaseSignIn} = require('./service')

exports.login=async (req,res)=>{
    try{
    const {userEmail, passWord}=req.body
    if(!(userEmail&&passWord)){
        return res.status(400).json({ error: 'Must enter Username and password' });
    }
    const result=await firebaseSignIn(userEmail,passWord)
    console.log(result)
    res.status(200).json({token: result.idToken, user:result.user})
    }catch(error){
        console.error("Login error ",error)
        if(error.message==="INVALID_PASSWORD"||error.message==="EMAIL_NOT_FOUND"){
            return res.status(401).json({ error: 'Invalid email or password' });
        }
        return res.status(500).json({error:"login failed"})
    }
}

exports.miscel = async(req,res)=>{
    res.send('Hello world')
}