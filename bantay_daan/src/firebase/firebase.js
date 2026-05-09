import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";


const firebaseConfig = {
  apiKey: "AIzaSyDl2jrx_Xy2WgQpMb-W4ZnG52GvUu9Dfmo",
  authDomain: "bantay-daan.firebaseapp.com",
  databaseURL: "https://bantay-daan-default-rtdb.firebaseio.com",
  projectId: "bantay-daan",
  storageBucket: "bantay-daan.firebasestorage.app",
  messagingSenderId: "303816241992",
  appId: "1:303816241992:web:960f27cb60387122e9f97d"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
