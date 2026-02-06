import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Epic Gold Shop | Comprar Oro WoW - Vender Oro WoW - Cuentas Premium",
  description:
    "Tienda #1 para comprar oro World of Warcraft, Turtle WoW, Albion Online. Vende tu oro seguro, entrega inmediata 24/7. Cuentas verificadas, precios competitivos.",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  )
}
