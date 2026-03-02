from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Image, Spacer, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os

# Create document
doc = SimpleDocTemplate(
    "/home/z/my-project/download/Oil_Imperium_Generated_Assets.pdf",
    pagesize=A4,
    title="Oil Imperium Generated Assets",
    author="Z.ai",
    creator="Z.ai",
    subject="AI-generated game assets for Oil Imperium Remake"
)

# Setup styles
styles = getSampleStyleSheet()
title_style = ParagraphStyle(
    'TitleStyle',
    parent=styles['Title'],
    fontSize=28,
    textColor=colors.HexColor('#f59e0b'),
    alignment=TA_CENTER,
    spaceAfter=20
)
heading_style = ParagraphStyle(
    'HeadingStyle',
    parent=styles['Heading2'],
    fontSize=18,
    textColor=colors.HexColor('#1f4e79'),
    spaceBefore=20,
    spaceAfter=10
)
desc_style = ParagraphStyle(
    'DescStyle',
    parent=styles['Normal'],
    fontSize=11,
    textColor=colors.HexColor('#666666'),
    alignment=TA_CENTER
)

story = []

# Title Page
story.append(Spacer(1, 2*inch))
story.append(Paragraph("🛢️ Oil Imperium Remake", title_style))
story.append(Paragraph("Generated Game Assets", styles['Heading2']))
story.append(Spacer(1, 0.5*inch))
story.append(Paragraph("AI-generated images for your retro oil business simulation game", desc_style))
story.append(Spacer(1, 0.3*inch))
story.append(Paragraph("12 Images Ready to Use", desc_style))
story.append(PageBreak())

# Image directory
image_dir = "/home/z/my-project/oil-imperium-remake/assets/generated/"

# Categories and their images
categories = {
    "🏆 Achievement Icons": [
        ("achievement_first_oil.png", "First Oil - Oil derrick with trophy"),
        ("achievement_money.png", "Millionaire - Gold coins and dollar bills"),
        ("achievement_global.png", "Global Empire - Globe with oil derricks"),
        ("achievement_tech.png", "Technology - Microchip and gear"),
        ("achievement_sabotage.png", "Saboteur - Dynamite bomb"),
    ],
    "🏢 Office Backgrounds": [
        ("office_1970s_background.png", "1970s Office - Wood paneling, green terminal"),
        ("office_1980s_background.png", "1980s Office - IBM PC, Memphis design"),
        ("office_1990s_background.png", "1990s Office - CRT monitors, minimalist"),
    ],
    "⚡ Events & Icons": [
        ("event_oil_spill.png", "Oil Spill Disaster - Environmental event"),
        ("icon_oil_barrel.png", "Oil Barrel - Blue barrel icon"),
        ("icon_contract.png", "Contract - Scroll with golden seal"),
    ],
    "🌅 Loading Screen": [
        ("loading_screen.png", "Loading Screen - Epic oil industry sunset landscape"),
    ],
}

for category, images in categories.items():
    story.append(Paragraph(category, heading_style))
    story.append(Spacer(1, 10))
    
    for filename, description in images:
        img_path = os.path.join(image_dir, filename)
        if os.path.exists(img_path):
            # Add image
            img = Image(img_path, width=4*inch, height=4*inch)
            img.hAlign = 'CENTER'
            story.append(img)
            
            # Add filename and description
            story.append(Paragraph(f"<b>{filename}</b>", desc_style))
            story.append(Paragraph(description, desc_style))
            story.append(Spacer(1, 20))
    
    story.append(PageBreak())

# Build PDF
doc.build(story)
print("✅ PDF created: /home/z/my-project/download/Oil_Imperium_Generated_Assets.pdf")
