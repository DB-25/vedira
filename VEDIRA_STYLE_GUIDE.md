# Vedira App - Official Style Guide

> **Version**: 1.0  
> **Last Updated**: December 2024  
> **Status**: Active  

## 📋 Table of Contents

1. [Brand Identity](#brand-identity)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Layout & Structure](#layout--structure)
5. [Components](#components)
6. [Spacing & Measurements](#spacing--measurements)
7. [Animations & Transitions](#animations--transitions)
8. [Interactive States](#interactive-states)
9. [Accessibility](#accessibility)
10. [Code Implementation](#code-implementation)

---

## 🎨 Brand Identity

### **App Name**: Vedira
### **Tagline**: "Your AI-powered learning companion"
### **Primary Logo**: School icon (`Icons.school_rounded`) with gradient background

### **Design Principles**
- **Modern & Clean**: Minimalist design with clear visual hierarchy
- **Accessible**: WCAG AA compliant color contrasts
- **Consistent**: Unified design language across all screens
- **User-Centric**: Intuitive navigation and clear call-to-actions

---

## 🌈 Color System

### **Theme Architecture**
The app supports **2 color palettes** × **2 modes** = **4 theme combinations**:

#### **Palette 1: Green Theme**
```
Primary Colors:
- Primary: #1B5E20 (Dark Green)
- Primary Light: #4CAF50 (Standard Green)
- Primary Container: #C8E6C9 (Light), #0F3A1A (Dark)

Secondary Colors:
- Secondary: #E91E63 (Pink)
- Secondary Container: #F8BBD0 (Light), #4A0E22 (Dark)

Accent Colors:
- Success: #4CAF50 (Green)
- Warning: #FF9800 (Orange)
- Error/Danger: #D32F2F (Red)

Surface Colors:
- Background: #FFFBFE (Light), #2E2E2E (Dark)
- Surface: #FFFBFE (Light), #424242 (Dark)
- Surface Container: #E6E0E9 (Light), #424242 (Dark)
```

#### **Palette 2: Blue Theme (Default)**
```
Primary Colors:
- Primary: #1976D2 (Material Blue)
- Primary Light: #2196F3 (Light Blue)
- Primary Container: #BBDEFB (Light), #0D47A1 (Dark)

Secondary Colors:
- Secondary: #424242 (Dark Gray)
- Secondary Container: #EEEEEE (Light), #616161 (Dark)

Accent Colors:
- Accent: #FF9800 (Orange)
- Highlight: #FFC107 (Amber)
- Danger: #D32F2F (Red)

Surface Colors:
- Background: #FFFBFE (Light), #1E1E1E (Dark)
- Surface: #FFFBFE (Light), #2E2E2E (Dark)
- Surface Container: #E6E0E9 (Light), #2E2E2E (Dark)
```

#### **Text Colors**
```
- On Surface: #1C1B1F (Light), #E8E8E8 (Dark)
- On Primary: #FFFFFF
- On Secondary: #FFFFFF
- On Error: #FFFFFF

Opacity Variations:
- 100%: Primary text
- 80%: Secondary text
- 70%: Tertiary text
- 60%: Disabled text
```

#### **Border & Outline Colors**
```
- Outline: #79747E (Light), #938F99 (Dark)
- Outline Variant: #CAC4D0 (Light), #49454F (Dark)
- Outline with Opacity: 15%, 20%, 30% for different emphasis levels
```

---

## 📝 Typography

### **Font Stack**
- **Headers & Titles**: [Inter](https://fonts.google.com/specimen/Inter) (Google Font)
- **Body Text & Labels**: [Poppins](https://fonts.google.com/specimen/Poppins) (Google Font)

### **Type Scale**

#### **Display Styles** (Inter)
```
Display Large:   57px / Weight 400 / Line Height 64px
Display Medium:  45px / Weight 400 / Line Height 52px
Display Small:   36px / Weight 400 / Line Height 44px
```

#### **Headlines** (Inter)
```
Headline Large:  32px / Weight 700 / Line Height 40px
Headline Medium: 28px / Weight 600 / Line Height 36px  
Headline Small:  24px / Weight 600 / Line Height 32px
```

#### **Titles** (Inter)
```
Title Large:     22px / Weight 600 / Line Height 28px
Title Medium:    16px / Weight 600 / Line Height 24px
Title Small:     14px / Weight 600 / Line Height 20px
```

#### **Body Text** (Poppins)
```
Body Large:      16px / Weight 400 / Line Height 24px
Body Medium:     14px / Weight 400 / Line Height 20px
Body Small:      12px / Weight 400 / Line Height 16px
```

#### **Labels** (Poppins)
```
Label Large:     14px / Weight 500 / Line Height 20px
Label Medium:    12px / Weight 500 / Line Height 16px
Label Small:     11px / Weight 500 / Line Height 16px
```

### **Usage Guidelines**
- **Headlines**: Page titles, section headers
- **Titles**: Card titles, component headers
- **Body**: Main content, descriptions
- **Labels**: Buttons, form labels, badges

---

## 🏗️ Layout & Structure

### **App Architecture**
- **Navigation**: Bottom navigation with floating action button
- **Scroll Type**: `CustomScrollView` with `SliverAppBar`
- **Layout Pattern**: Single-column with card-based content

### **App Bar Specifications**
```
Type: SliverAppBar
- Floating: true
- Snap: true
- Pinned: false
- Elevation: 10
- ScrolledUnderElevation: 0
- Background: Surface + Primary overlay (18% light, 25% dark)
- Height: 56px (collapsed)
```

#### **App Bar Content**
```
Logo Container:
- Size: 32×32px
- Background: Linear gradient (Primary → Secondary)
- Border Radius: 8px
- Icon: school_rounded, 18px, white

Title:
- Text: "Vedira"
- Style: titleLarge, bold
- Color: onSurface

Actions:
- Theme Selector: PopupMenuButton
- More Menu: PopupMenuButton with 50px offset
```

### **Background Colors**
```
Body Background:
- Light: Surface + Primary overlay (8% opacity)
- Dark: Surface + Primary overlay (12% opacity)
```

---

## 🧩 Components

### **Course Cards**
The primary content component for displaying course information.

#### **Structure**
```
Container Properties:
- Margin: 16px horizontal, 4px vertical
- Background: Surface with transparency (85% light, 90% dark)
- Border Radius: 20px
- Border: 1px outline (15% opacity)
- Clip Behavior: antiAlias

Shadow System:
- Primary: shadow 8% opacity, 12px blur, (0,4) offset
- Secondary: primary 5% opacity, 20px blur, (0,8) offset
```

#### **Content Layout**
```
1. Cover Image (if available)
   - Full width
   - Aspect ratio maintained
   - Authenticated image loading

2. Content Section (16px padding)
   - Course Title: titleMedium, bold, max 2 lines
   - Course Description: bodySmall, 70% opacity, max 2 lines, 1.3 line height
   - Spacing: 6px between title and description, 12px before meta info

3. Meta Information Row
   - Content Badge: 12px radius, primary 10% background
   - Arrow Icon: 16px, arrow_forward_ios, 30% opacity
```

#### **Interactive Elements**
```
Star Button:
- Position: Absolute top-right (8px from edges)
- Size: 40×40px tap target
- Icon: star_border / star
- Color: Primary (starred), outline (unstarred)
- Animation: 200ms fade transition

Main Tap Area:
- Full card clickable via InkWell
- Splash effect on tap
- Navigation to course details
```

### **Buttons**

#### **Elevated Button**
```
Background: Primary color
Foreground: On Primary color
Text Style: Poppins, 16px, Weight 600
Shape: 12px border radius
Padding: 24px horizontal, 12px vertical
Elevation: Material 3 defaults
```

#### **Outlined Button**
```
Background: Transparent
Foreground: Primary color
Border: Primary color
Text Style: Poppins, 16px, Weight 600
Shape: 12px border radius
Padding: 24px horizontal, 12px vertical
```

#### **Floating Action Button**
```
Type: Extended FAB
Icon: add_rounded
Label: "New Course"
Background: Primary color
Foreground: On Primary color
```

### **Theme Selector**
```
Type: PopupMenuButton
Icon: Dynamic based on theme state
- Light Mode: light_mode / light_mode_outlined
- Dark Mode: palette / palette_outlined

Menu Items (4 total):
1. Green Light: Circle indicator + "Green Light"
2. Green Dark: Circle indicator + "Green Dark"
3. Blue Light: Circle indicator + "Blue Light"  
4. Blue Dark: Circle indicator + "Blue Dark"

Quick Actions:
- Toggle Light/Dark
- Switch Palette
```

### **Feature Cards** (Onboarding)
```
Container:
- Width: Full width
- Padding: 20px
- Background: Surface color
- Border: Outline 30% opacity, 1px
- Border Radius: 12px
- Shadow: 5% opacity, 8px blur, (0,2) offset

Layout:
- Row with icon container + text content
- Icon Container: 12px padding, 10px radius, primary 10% background
- Icon: 28px size, primary color
- Text: titleMedium (title), bodyMedium 80% opacity (description)
```

### **Input Fields**
```
Fill Color: surfaceContainerHighest 50% opacity
Border: outline 20% opacity
Border Radius: 12px
Focus Border: Primary color, 2px width
Content Padding: 16px horizontal, 12px vertical
```

### **Dialogs**
```
Background: Surface color
Surface Tint: Transparent
Elevation: 8
Border Radius: 16px
```

---

## 📐 Spacing & Measurements

### **Spacing Scale**
```
xs:  4px   - Tight spacing between related elements
sm:  8px   - Small gaps, form field spacing
md:  16px  - Default spacing, card padding
lg:  24px  - Section spacing, large padding
xl:  32px  - Page margins, major section separation
xxl: 40px  - Hero section spacing
```

### **Component Measurements**
```
App Bar Height: 56px
Course Card Border Radius: 20px
Button Border Radius: 12px
Input Field Border Radius: 12px
Dialog Border Radius: 16px
Bottom Sheet Border Radius: 16px (top only)

Icon Sizes:
- Small: 16px
- Medium: 20px
- Large: 24px
- XLarge: 32px
- Hero: 48px+
```

### **Hit Target Sizes**
```
Minimum Touch Target: 48×48px
Button Height: 48px minimum
Icon Button: 48×48px
FAB: 56×56px (standard), Variable (extended)
```

---

## 🎬 Animations & Transitions

### **Duration Scale**
```
Micro:  100ms - Hover effects, small state changes
Short:  200ms - Button states, icon changes
Medium: 300ms - Card transitions, navigation
Long:   500ms - Page transitions, complex animations
```

### **Easing Curves**
```
Standard: Curves.easeInOut - Default for most animations
Decelerate: Curves.easeOut - Entering elements
Accelerate: Curves.easeIn - Exiting elements
```

### **Specific Animations**
```
Course Card State Changes:
- Duration: 300ms
- Curve: easeInOut
- Properties: position, opacity, scale

Star Toggle:
- Duration: 200ms
- Curve: easeInOut
- Properties: color, icon

Page Transitions:
- Duration: 300ms
- Type: MaterialPageRoute default
```

---

## 🎯 Interactive States

### **Button States**
```
Default: Base colors as defined
Hover: Subtle elevation increase
Pressed: Slight scale reduction + color shift
Disabled: 60% opacity
Loading: Progress indicator overlay
```

### **Card States**
```
Default: Base styling
Hover: Subtle shadow increase (web)
Pressed: InkWell splash effect
Selected: Border highlight (if applicable)
```

### **Form Field States**
```
Default: Filled with outline
Focus: Primary border (2px), elevated
Error: Error color border + helper text
Disabled: 60% opacity
```

---

## ♿ Accessibility

### **Color Contrast**
- **AA Compliance**: All text meets WCAG 2.1 AA standards
- **Minimum Ratios**: 4.5:1 for normal text, 3:1 for large text

### **Interactive Elements**
- **Touch Targets**: Minimum 48×48dp
- **Focus Indicators**: Visible focus rings
- **Screen Reader**: Semantic labels and hints

### **Typography**
- **Readable Fonts**: Inter and Poppins chosen for legibility
- **Size Scale**: Follows Material Design recommendations
- **Line Height**: 1.4-1.6 for optimal readability

---

## 💻 Code Implementation

### **Theme Access**
```dart
// Get current theme
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

// Get theme manager
final themeManager = Provider.of<ThemeManager>(context);
final isDarkMode = themeManager.isDarkMode;
```

### **Color Usage Examples**
```dart
// Primary colors
backgroundColor: colorScheme.primary,
foregroundColor: colorScheme.onPrimary,

// Surface colors with opacity
backgroundColor: colorScheme.surface.withOpacity(0.85),

// Outline colors
borderColor: colorScheme.outline.withOpacity(0.2),
```

### **Typography Examples**
```dart
// Headline
Text(
  'Welcome to Vedira',
  style: theme.textTheme.headlineMedium?.copyWith(
    fontWeight: FontWeight.bold,
    color: colorScheme.primary,
  ),
)

// Body text
Text(
  'Description text',
  style: theme.textTheme.bodyMedium?.copyWith(
    color: colorScheme.onSurface.withOpacity(0.8),
  ),
)
```

### **Common Patterns**
```dart
// Glass morphism effect
final cardColor = theme.brightness == Brightness.light
    ? Color.alphaBlend(colorScheme.surface.withOpacity(0.85), Colors.white)
    : Color.alphaBlend(colorScheme.surface.withOpacity(0.90), colorScheme.surface);

// Tinted background
final bodyBackgroundColor = theme.brightness == Brightness.light
    ? Color.alphaBlend(colorScheme.primary.withOpacity(0.08), colorScheme.surface)
    : Color.alphaBlend(colorScheme.primary.withOpacity(0.12), colorScheme.surface);
```

---

## 📚 Resources

### **Design Tokens**
- All colors, spacing, and typography values are defined in `lib/utils/constants.dart`
- Theme implementation in `lib/utils/theme_manager.dart`

### **Key Files**
- `lib/utils/theme_manager.dart` - Theme system
- `lib/utils/constants.dart` - Design tokens
- `lib/widgets/course_card.dart` - Primary component
- `lib/screens/home_screen.dart` - Layout reference

### **External Dependencies**
- Google Fonts: Inter, Poppins
- Material 3 Design System
- Flutter framework components

---

## 🔄 Changelog

### Version 1.0 (December 2024)
- Initial style guide creation
- Documented home screen patterns
- Established color system and typography
- Defined component specifications

---

**For questions or updates to this style guide, please contact the development team.** 