// Import Firebase scripts needed for messaging
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging.js');

// Initialize Firebase with your web config
firebase.initializeApp({
  apiKey: "AIzaSyDpzESQLJBTJBsAp6LenM0pFQQLrAsCivQ",
  appId: "1:599849169513:web:f8716a4a2581072a8468f8",
  messagingSenderId: "599849169513",
  projectId: "sda-youth-app",
  authDomain: "sda-youth-app.firebaseapp.com",
  storageBucket: "sda-youth-app.firebasestorage.app",
  measurementId: "G-NDN2F9649S"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();
