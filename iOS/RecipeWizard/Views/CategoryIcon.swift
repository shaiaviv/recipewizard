import SwiftUI

/// Custom hand-drawn icon for each recipe category.
/// Renders entirely in `color` — pass `category.color` when unselected, `.white` when selected.
struct CategoryIcon: View {
    let category: RecipeListViewModel.RecipeCategory
    let color: Color
    var size: CGFloat = 24

    var body: some View {
        Canvas { ctx, canvasSize in
            // All paths are drawn in a 100×100 coordinate space then scaled to canvas size.
            let s   = canvasSize.width / 100
            let lw  = 7.0 * s
            let lws = 5.0 * s          // thin strokes
            let shade = GraphicsContext.Shading.color(color)
            let t     = CGAffineTransform(scaleX: s, y: s)
            let round = StrokeStyle(lineWidth: lw,  lineCap: .round, lineJoin: .round)
            let thin  = StrokeStyle(lineWidth: lws, lineCap: .round, lineJoin: .round)

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
            func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
            }

            switch category {

            // MARK: All — plate + fork + knife
            case .all:
                ctx.stroke(oval(12, 12, 76, 76).applying(t), with: shade, lineWidth: lw)
                // Fork: centre handle + two outer tines
                var fork = Path()
                fork.move(to: pt(35, 28)); fork.addLine(to: pt(35, 72))
                fork.move(to: pt(29, 28)); fork.addLine(to: pt(29, 44))
                fork.move(to: pt(41, 28)); fork.addLine(to: pt(41, 44))
                ctx.stroke(fork.applying(t), with: shade, style: round)
                // Knife: straight handle + curved blade
                var knife = Path()
                knife.move(to: pt(65, 72))
                knife.addLine(to: pt(65, 44))
                knife.addCurve(to: pt(65, 28), control1: pt(73, 40), control2: pt(73, 32))
                ctx.stroke(knife.applying(t), with: shade, style: round)

            // MARK: Favorites — solid heart
            case .favorites:
                var heart = Path()
                heart.move(to: pt(50, 78))
                heart.addCurve(to: pt(10, 37), control1: pt(22, 72), control2: pt(10, 56))
                heart.addCurve(to: pt(50, 22), control1: pt(10, 14), control2: pt(33, 14))
                heart.addCurve(to: pt(90, 37), control1: pt(67, 14), control2: pt(90, 14))
                heart.addCurve(to: pt(50, 78), control1: pt(90, 56), control2: pt(78, 72))
                heart.closeSubpath()
                ctx.fill(heart.applying(t), with: shade)

            // MARK: Italian — bowl + pasta waves
            case .italian:
                var bowl = Path()
                bowl.move(to: pt(14, 52))
                bowl.addCurve(to: pt(86, 52), control1: pt(14, 86), control2: pt(86, 86))
                ctx.stroke(bowl.applying(t), with: shade, style: round)
                var rim = Path()
                rim.move(to: pt(12, 52)); rim.addLine(to: pt(88, 52))
                ctx.stroke(rim.applying(t), with: shade, style: round)
                // Noodle S-waves above bowl
                for (y, xl, xr): (CGFloat, CGFloat, CGFloat) in [(40, 22, 78), (28, 28, 72), (17, 32, 68)] {
                    var wave = Path()
                    wave.move(to: pt(xl, y))
                    wave.addCurve(to: pt(xr, y),
                                  control1: pt(xl + 14, y - 9),
                                  control2: pt(xr - 14, y + 9))
                    ctx.stroke(wave.applying(t), with: shade, style: thin)
                }

            // MARK: Mexican — taco shell + filling layers
            case .mexican:
                var shell = Path()
                shell.move(to: pt(14, 26))
                shell.addCurve(to: pt(86, 26), control1: pt(6, 92), control2: pt(94, 92))
                ctx.stroke(shell.applying(t), with: shade, style: round)
                for (y, xl, xr): (CGFloat, CGFloat, CGFloat) in [(36, 22, 78), (50, 20, 80), (63, 20, 80)] {
                    var fill = Path()
                    fill.move(to: pt(xl, y))
                    fill.addQuadCurve(to: pt(xr, y), control: pt(50, y + 5))
                    ctx.stroke(fill.applying(t), with: shade, style: thin)
                }

            // MARK: Asian — bowl + crossed chopsticks
            case .asian:
                var bowl = Path()
                bowl.move(to: pt(14, 56))
                bowl.addCurve(to: pt(86, 56), control1: pt(14, 86), control2: pt(86, 86))
                ctx.stroke(bowl.applying(t), with: shade, style: round)
                var rim = Path()
                rim.move(to: pt(12, 56)); rim.addLine(to: pt(88, 56))
                ctx.stroke(rim.applying(t), with: shade, style: round)
                var c1 = Path(); c1.move(to: pt(28, 14)); c1.addLine(to: pt(52, 50))
                var c2 = Path(); c2.move(to: pt(44, 10)); c2.addLine(to: pt(68, 48))
                ctx.stroke(c1.applying(t), with: shade, style: round)
                ctx.stroke(c2.applying(t), with: shade, style: round)

            // MARK: Chicken — drumstick outline
            case .chicken:
                ctx.stroke(oval(22, 14, 56, 48).applying(t), with: shade, lineWidth: lw)
                // Bone stem
                var bone = Path()
                bone.move(to: pt(43, 60))
                bone.addLine(to: pt(43, 76))
                bone.addQuadCurve(to: pt(57, 76), control: pt(50, 86))
                bone.addLine(to: pt(57, 60))
                ctx.stroke(bone.applying(t), with: shade, style: round)
                // Knobs at base
                ctx.stroke(oval(35, 73, 11, 11).applying(t), with: shade, lineWidth: lw)
                ctx.stroke(oval(54, 73, 11, 11).applying(t), with: shade, lineWidth: lw)

            // MARK: Seafood — fish silhouette
            case .seafood:
                ctx.stroke(oval(10, 33, 60, 34).applying(t), with: shade, lineWidth: lw)
                // V-tail
                var tail = Path()
                tail.move(to: pt(68, 33)); tail.addLine(to: pt(88, 50)); tail.addLine(to: pt(68, 67))
                ctx.stroke(tail.applying(t), with: shade, style: round)
                // Eye
                ctx.stroke(oval(20, 44, 9, 9).applying(t), with: shade, lineWidth: lws)
                // Dorsal fin
                var fin = Path()
                fin.move(to: pt(24, 33))
                fin.addQuadCurve(to: pt(55, 33), control: pt(38, 15))
                ctx.stroke(fin.applying(t), with: shade, style: thin)

            // MARK: Meat — steak blob + grill marks
            case .meat:
                var steak = Path()
                steak.move(to: pt(18, 46))
                steak.addCurve(to: pt(48, 20), control1: pt(16, 28), control2: pt(36, 16))
                steak.addCurve(to: pt(82, 38), control1: pt(62, 24), control2: pt(84, 26))
                steak.addCurve(to: pt(64, 74), control1: pt(84, 56), control2: pt(78, 74))
                steak.addCurve(to: pt(26, 74), control1: pt(48, 74), control2: pt(38, 80))
                steak.addCurve(to: pt(18, 46), control1: pt(10, 66), control2: pt(12, 54))
                steak.closeSubpath()
                ctx.stroke(steak.applying(t), with: shade, style: round)
                var g1 = Path(); g1.move(to: pt(32, 38)); g1.addLine(to: pt(48, 66))
                var g2 = Path(); g2.move(to: pt(48, 30)); g2.addLine(to: pt(64, 58))
                ctx.stroke(g1.applying(t), with: shade, style: thin)
                ctx.stroke(g2.applying(t), with: shade, style: thin)

            // MARK: Healthy — carrot + leaves
            case .healthy:
                var carrot = Path()
                carrot.move(to: pt(50, 87))
                carrot.addCurve(to: pt(28, 36), control1: pt(38, 78), control2: pt(22, 54))
                carrot.addLine(to: pt(38, 28)); carrot.addLine(to: pt(62, 28))
                carrot.addLine(to: pt(72, 36))
                carrot.addCurve(to: pt(50, 87), control1: pt(78, 54), control2: pt(62, 78))
                carrot.closeSubpath()
                ctx.stroke(carrot.applying(t), with: shade, style: round)
                // Three leaf stems
                var l1 = Path()
                l1.move(to: pt(42, 27)); l1.addCurve(to: pt(28, 8), control1: pt(28, 20), control2: pt(20, 12))
                var l2 = Path()
                l2.move(to: pt(50, 24)); l2.addCurve(to: pt(50, 6), control1: pt(42, 16), control2: pt(58, 10))
                var l3 = Path()
                l3.move(to: pt(58, 27)); l3.addCurve(to: pt(72, 8), control1: pt(72, 20), control2: pt(80, 12))
                ctx.stroke(l1.applying(t), with: shade, style: thin)
                ctx.stroke(l2.applying(t), with: shade, style: thin)
                ctx.stroke(l3.applying(t), with: shade, style: thin)

            // MARK: Dessert — cupcake + cherry
            case .dessert:
                // Wrapper
                var wrap = Path()
                wrap.move(to: pt(28, 80)); wrap.addLine(to: pt(72, 80))
                wrap.addLine(to: pt(66, 54)); wrap.addLine(to: pt(34, 54))
                wrap.closeSubpath()
                ctx.stroke(wrap.applying(t), with: shade, style: round)
                // Vertical wrapper pleats
                for wx: CGFloat in [42, 50, 58] {
                    var pl = Path()
                    pl.move(to: pt(wx + (wx - 50) * (-0.15), 54))
                    pl.addLine(to: pt(wx, 80))
                    ctx.stroke(pl.applying(t), with: shade, style: thin)
                }
                // Frosting dome
                var dome = Path()
                dome.move(to: pt(32, 54))
                dome.addCurve(to: pt(68, 54), control1: pt(30, 18), control2: pt(70, 18))
                ctx.stroke(dome.applying(t), with: shade, style: round)
                // Cherry + stem
                ctx.stroke(oval(44, 12, 12, 12).applying(t), with: shade, lineWidth: lw)
                var stem = Path()
                stem.move(to: pt(50, 24))
                stem.addCurve(to: pt(56, 18), control1: pt(52, 22), control2: pt(58, 22))
                ctx.stroke(stem.applying(t), with: shade, style: thin)

            // MARK: Breakfast — pancake stack + butter + syrup
            case .breakfast:
                for (x, y, w, h): (CGFloat, CGFloat, CGFloat, CGFloat) in
                    [(14, 66, 72, 13), (18, 52, 64, 12), (22, 38, 56, 12)] {
                    ctx.stroke(oval(x, y, w, h).applying(t), with: shade, lineWidth: lw)
                }
                // Butter pat
                ctx.stroke(oval(36, 32, 18, 8).applying(t), with: shade, lineWidth: lws)
                // Syrup drip
                var drip = Path()
                drip.move(to: pt(76, 52))
                drip.addCurve(to: pt(80, 68), control1: pt(82, 58), control2: pt(82, 64))
                drip.addQuadCurve(to: pt(76, 72), control: pt(80, 74))
                ctx.stroke(drip.applying(t), with: shade, style: thin)

            // MARK: Soup — bowl + steam wisps
            case .soup:
                var bowl = Path()
                bowl.move(to: pt(12, 57))
                bowl.addCurve(to: pt(88, 57), control1: pt(12, 88), control2: pt(88, 88))
                ctx.stroke(bowl.applying(t), with: shade, style: round)
                var rim = Path()
                rim.move(to: pt(10, 57)); rim.addLine(to: pt(90, 57))
                ctx.stroke(rim.applying(t), with: shade, style: round)
                // Three wavy steam lines
                for x: CGFloat in [34, 50, 66] {
                    var steam = Path()
                    steam.move(to: pt(x, 50))
                    steam.addCurve(to: pt(x, 22),
                                   control1: pt(x - 9, 42),
                                   control2: pt(x + 9, 32))
                    ctx.stroke(steam.applying(t), with: shade, style: thin)
                }
            }
        }
        .frame(width: size, height: size)
    }
}
