#!/bin/bash

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "🚀 Mengganti isi $TARGET_FILE..."

if [ -f "$TARGET_FILE" ]; then
  cp "$TARGET_FILE" "$BACKUP_FILE"
  echo "📦 Backup dibuat di $BACKUP_FILE"
fi

cat > "$TARGET_FILE" << 'EOF'
@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-800'],
])

@section('container')
<div id="modal-portal"></div>
<div id="app"></div>

<style>
.telegram-float{
position:fixed;
bottom:25px;
right:25px;
width:60px;
height:60px;
border-radius:50%;
background:linear-gradient(135deg,#6d5cff,#8a7dff);
display:flex;
align-items:center;
justify-content:center;
box-shadow:0 0 20px rgba(108,92,255,0.7);
cursor:pointer;
z-index:9999;
transition:0.3s;
}
.telegram-float:hover{
transform:scale(1.1);
}
.telegram-float svg{
width:30px;
height:30px;
fill:white;
}

.contact-box{
position:fixed;
bottom:100px;
right:25px;
width:260px;
background:#1e293b;
border-radius:12px;
padding:15px;
color:white;
font-family:sans-serif;
box-shadow:0 0 25px rgba(0,0,0,0.5);
z-index:9999;
display:none;
}

.contact-title{
text-align:center;
font-size:16px;
margin-bottom:12px;
font-weight:bold;
}

.contact-item{
display:flex;
align-items:center;
padding:10px;
border-radius:8px;
background:#334155;
cursor:pointer;
transition:0.2s;
margin-bottom:8px;
}
.contact-item:hover{
background:#475569;
}

.contact-icon{
width:40px;
height:40px;
background:linear-gradient(135deg,#6d5cff,#8a7dff);
border-radius:10px;
display:flex;
align-items:center;
justify-content:center;
margin-right:12px;
box-shadow:0 0 10px rgba(108,92,255,0.5);
}
.contact-icon svg{
width:24px;
height:24px;
fill:white;
}

.contact-text{
display:flex;
flex-direction:column;
}
.contact-text span{
font-size:14px;
font-weight:600;
}
.contact-text small{
opacity:0.7;
font-size:12px;
}

.close-btn{
margin-top:10px;
width:100%;
padding:6px;
border:none;
border-radius:8px;
background:#0f172a;
color:white;
cursor:pointer;
}
</style>

<div class="contact-box" id="contactBox">
<div class="contact-title">Contact Owner</div>

<!-- Contact Owner -->
<div class="contact-item" onclick="window.open('https://t.me/Rexzzzy_bot','_blank')">
<div class="contact-icon">
<svg viewBox="0 0 24 24">
<path d="M12 12c2.7 0 5-2.3 5-5s-2.3-5-5-5-5 2.3-5 5 2.3 5 5 5zm0 2c-3.3 0-10 1.7-10 5v3h20v-3c0-3.3-6.7-5-10-5z"/>
</svg>
</div>
<div class="contact-text">
<span>Telegram Owner</span>
</div>
</div>

<!-- Buy Panel -->
<div class="contact-item" onclick="window.open('https://t.me/Rexzzzy_bot','_blank')">
<div class="contact-icon">
<svg viewBox="0 0 24 24">
<path d="M7 18c-1.1 0-1.99.9-1.99 2S5.9 22 7 22s2-.9 2-2-.9-2-2-2zm10-2c-1.1 0-1.99.9-1.99 2S15.9 22 17 22s2-.9 2-2-.9-2-2-2zM7.16 14h9.45c.75 0 1.41-.41 1.75-1.03L21 6H6.21l-.94-2H2v2h2l3.6 7.59-1.35 2.45c-.16.29-.25.62-.25.96 0 1.1.9 2 2 2h12v-2H8.42c-.14 0-.25-.11-.25-.25z"/>
</svg>
</div>
<div class="contact-text">
<span>Buy Panel</span>
</div>
</div>

<!-- Buy VPS -->
<div class="contact-item" onclick="window.open('https://t.me/Rexzzzy_bot','_blank')">
<div class="contact-icon">
<svg viewBox="0 0 24 24">
<path d="M4 6h16v12H4zM2 4v16h20V4H2zm4 4h4v2H6V8zm0 4h8v2H6v-2z"/>
</svg>
</div>
<div class="contact-text">
<span>Buy VPS</span>
</div>
</div>

<button class="close-btn" onclick="toggleContact()">Close</button>
</div>

<div class="telegram-float" onclick="toggleContact()">
<svg viewBox="0 0 24 24">
<path d="M9.04 15.47l-.39 5.46c.56 0 .8-.24 1.1-.53l2.64-2.52 5.47 4c1 .56 1.7.27 1.96-.92l3.56-16.67c.31-1.45-.52-2.02-1.5-1.65L1.46 9.9c-1.4.56-1.38 1.34-.24 1.7l5.42 1.69L19.1 5.6c.59-.39 1.13-.17.69.22"/>
</svg>
</div>

<script>
function toggleContact(){
const box=document.getElementById("contactBox");
box.style.display = box.style.display === "block" ? "none" : "block";
}
</script>

@endsection
EOF

echo "✅ Contact Owner + Buy Panel + Buy VPS berhasil ditambahkan."