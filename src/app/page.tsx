"use client";

export default function ImageGallery() {
  // Direct image paths - will be served from public folder
  const images = [
    { src: "/generated_images/achievement_first_oil.png", name: "achievement_first_oil.png", desc: "Oil derrick with trophy - First Oil", cat: "Achievements" },
    { src: "/generated_images/achievement_money.png", name: "achievement_money.png", desc: "Gold coins - Millionaire", cat: "Achievements" },
    { src: "/generated_images/achievement_global.png", name: "achievement_global.png", desc: "Globe with derricks - Global Empire", cat: "Achievements" },
    { src: "/generated_images/achievement_tech.png", name: "achievement_tech.png", desc: "Microchip - Technology", cat: "Achievements" },
    { src: "/generated_images/achievement_sabotage.png", name: "achievement_sabotage.png", desc: "Dynamite - Saboteur", cat: "Achievements" },
    { src: "/generated_images/office_1970s_background.png", name: "office_1970s_background.png", desc: "1970s office with green terminal", cat: "Offices" },
    { src: "/generated_images/office_1980s_background.png", name: "office_1980s_background.png", desc: "1980s IBM PC office", cat: "Offices" },
    { src: "/generated_images/office_1990s_background.png", name: "office_1990s_background.png", desc: "1990s modern office", cat: "Offices" },
    { src: "/generated_images/event_oil_spill.png", name: "event_oil_spill.png", desc: "Oil spill disaster", cat: "Events" },
    { src: "/generated_images/icon_oil_barrel.png", name: "icon_oil_barrel.png", desc: "Oil barrel icon", cat: "Icons" },
    { src: "/generated_images/icon_contract.png", name: "icon_contract.png", desc: "Contract scroll", cat: "Icons" },
    { src: "/generated_images/loading_screen.png", name: "loading_screen.png", desc: "Sunset oil field", cat: "Loading" },
  ];

  const cats = ["Achievements", "Offices", "Events", "Icons", "Loading"];
  
  return (
    <div style={{minHeight: "100vh", background: "#0f172a", color: "white", padding: 24}}>
      <div style={{maxWidth: 1200, margin: "0 auto"}}>
        <h1 style={{fontSize: 32, color: "#fbbf24", textAlign: "center", marginBottom: 8}}>
          Generated Game Assets
        </h1>
        <p style={{textAlign: "center", color: "#94a3b8", marginBottom: 32}}>
          12 AI-generated images for Oil Imperium Remake
        </p>
        
        {cats.map(cat => (
          <div key={cat} style={{marginBottom: 40}}>
            <h2 style={{color: "#fbbf24", fontSize: 20, marginBottom: 16, borderBottom: "1px solid #334155", paddingBottom: 8}}>
              {cat === "Achievements" && "🏆"} {cat === "Offices" && "🏢"} {cat === "Events" && "⚡"} {cat === "Icons" && "🔧"} {cat === "Loading" && "🌅"} {cat}
            </h2>
            <div style={{display: "grid", gridTemplateColumns: cat === "Offices" || cat === "Loading" ? "repeat(auto-fit, minmax(350px, 1fr))" : "repeat(auto-fit, minmax(200px, 1fr))", gap: 16}}>
              {images.filter(i => i.cat === cat).map(img => (
                <div key={img.name} style={{background: "#1e293b", borderRadius: 8, overflow: "hidden"}}>
                  <div style={{aspectRatio: cat === "Offices" || cat === "Loading" ? "16/9" : "1/1", background: "#0f172a", display: "flex", alignItems: "center", justifyContent: "center", padding: 8}}>
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={img.src} alt={img.desc} style={{maxWidth: "100%", maxHeight: "100%", objectFit: "contain"}} />
                  </div>
                  <div style={{padding: 12}}>
                    <div style={{color: "#fbbf24", fontSize: 13, fontWeight: 500}}>{img.name}</div>
                    <div style={{color: "#94a3b8", fontSize: 12, marginTop: 4}}>{img.desc}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
        
        <div style={{background: "#1e293b", borderRadius: 8, padding: 20, marginTop: 40, textAlign: "center"}}>
          <p style={{color: "#4ade80"}}>Right-click any image and select "Save image as..." to download</p>
        </div>
      </div>
    </div>
  );
}
