import { useState } from "react";
import { motion } from "framer-motion";
import React from 'react';

function App() {
  const [hovered, setHovered] = useState(false);

  return (
    <div className="flex h-screen w-full items-center justify-center bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500">
      <motion.div
        className="p-10 rounded-2xl bg-white shadow-2xl text-center max-w-lg"
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        whileHover={{ scale: 1.05, rotate: 1 }}
      >
        <motion.h1 
          className="text-4xl font-extrabold text-gray-900 drop-shadow-md"
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.3, duration: 0.6 }}
        >
          🌟 Application de Test pour Cloud DevOps 🌟
        </motion.h1>
        <motion.p 
          className="text-lg text-gray-800 mt-4"
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.6 }}
        >
          Cette application est une simple démo pour tester l'intégration et le déploiement dans un environnement cloud Azure.
        </motion.p>
        <motion.button
          className="mt-6 px-6 py-3 rounded-lg bg-gradient-to-r from-yellow-400 to-red-500 text-white text-lg font-semibold shadow-lg hover:scale-110 transition-all"
          whileHover={{ scale: 1.15, rotate: 3 }}
          whileTap={{ scale: 0.95 }}
          onMouseEnter={() => setHovered(true)}
          onMouseLeave={() => setHovered(false)}
        >
          {hovered ? "🚀 Tester le déploiement!" : "Lancer le test"}
        </motion.button>
      </motion.div>
    </div>
  );
}

export default App;
