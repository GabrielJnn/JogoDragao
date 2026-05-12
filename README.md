# 🐉 Jogo do Dragão

Um simulador de voo imersivo de um **dragão** feito em **Godot 4.3** com gráficos **3D Cinemáticos**.

## 🎮 Sobre o Jogo

Você controla um dragão com mecânicas de voo avançadas em 6 Graus de Liberdade (6DOF), simulando o comportamento de um caça/jato. O jogo se destaca por seus gráficos hiper-realistas que incluem iluminação global dinâmica (SDFGI), oclusão de ambiente (SSAO), Tone Mapping da indústria cinematográfica (ACES) e verdadeiras Nuvens Volumétricas dinâmicas através das quais o dragão pode voar. 

O cenário foi construído focado no estilo WYSIWYG, possuindo um enorme mundo Low-Poly imerso em uma atmosfera fantástica.

## 🕹️ Controles de Voo (Estilo Caça)

A física foi invertida para trazer o máximo de imersão de um simulador:

| Tecla | Ação |
|---|---|
| `W` | **Pitch (Arfagem)** - Abaixar o nariz do dragão |
| `S` | **Pitch (Arfagem)** - Levantar o nariz do dragão |
| `A` | **Roll (Rolagem)** - Inclinar corpo para a esquerda |
| `D` | **Roll (Rolagem)** - Inclinar corpo para a direita |
| `Q` | **Yaw (Guinada)** - Virar pescoço e corpo à esquerda |
| `E` | **Yaw (Guinada)** - Virar pescoço e corpo à direita |
| `Espaço` / `Enter` | Bater asas (impulso de *Afterburner* com alta conservação) |

## 🛠️ Tecnologias e Features Visuais

- **Engine:** [Godot 4](https://godotengine.org/) (GDScript)
- **Física de Voo 6DOF:** `CharacterBody3D` focado em rotações relativas (Quaternions e Basis).
- **Gráficos Avançados:** Iluminação Global (SDFGI), Iluminação Indireta (SSIL), Glow/Bloom e ACES Tonemapping.
- **Ambiente:** Céu em 360º de altíssima resolução (`PanoramaSkyMaterial`) e terrenos Low Poly assados na raiz.
- **Nuvens:** Sistema dinâmico com 40 *FogVolumes* distribuídos em diferentes faixas de altitude para imersão aérea real.
- **Câmera Dinâmica:** Câmera de terceira pessoa suave usando interpolação `Lerp` e `Slerp` para simular sensação de inércia em alta velocidade.

## 🚀 Como Rodar

1. Instale o [Godot 4](https://godotengine.org/download).
2. Clone este repositório:
   ```bash
   git clone https://github.com/GabrielJnn/JogoDragao.git
   ```
3. Abra o Godot 4, clique em **Import** e selecione a pasta do projeto.
4. Pressione **F5** para rodar a cena principal.

## 📌 Status

> 🟢 **Fase Atual:** Física de voo e ambiente base 100% implementados. Jogo navegável com gráficos cinematográficos finalizados.
