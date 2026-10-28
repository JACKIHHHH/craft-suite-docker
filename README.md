# Craft Suite en Docker

Sirve en tu red local las **13 apps de [ArtCraft](https://github.com/storytold)**, las alternativas libres a Adobe y Office, para usarlas desde el navegador de cualquier dispositivo (Mac, PC, iPad, Linux…) sin instalar nada.

| App | Para qué | Equivale a |
|---|---|---|
| PhotoCraft | Edición de imágenes | Photoshop |
| VectorCraft | Ilustración vectorial | Illustrator |
| DesignCraft | Maquetación | InDesign |
| LightCraft | Revelado RAW | Lightroom |
| FigCraft | Diseño de interfaces | Figma |
| FilmCraft | Edición de vídeo | Premiere Pro |
| EffectCraft | Animación y efectos | After Effects |
| SoundCraft | Audio | Audition |
| PdfCraft | PDF | Acrobat |
| WordCraft | Documentos | Word |
| GridCraft | Hojas de cálculo | Excel |
| DeckCraft | Presentaciones | PowerPoint |
| CADCraft | Dibujo técnico | AutoCAD |

## Cómo funciona

ArtCraft publica en cada release una versión **web (WebAssembly)** oficial de cada app (`<app>-web-<versión>.zip`). Este proyecto:

1. Descarga esas versiones web desde los releases de GitHub (`actualizar.sh`).
2. Las sirve con un **nginx** ligero, con el tipo MIME correcto para `.wasm`, compresión gzip y caché.
3. Añade una página de inicio con todas las apps.

Todo el trabajo (editar, renderizar, exportar) lo hace **el navegador del dispositivo**. El servidor solo entrega archivos estáticos, así que consume muy poco: unos 10 MB de RAM, CPU prácticamente a cero y unos 550 MB de disco para las 13 apps.

## Instalación

Necesitas Docker con Compose y salida a internet (solo para descargar las apps).

```sh
git clone https://github.com/JACKIHHHH/craft-suite-docker.git
cd craft-suite-docker
docker compose run --rm actualizar   # descarga las 13 apps (~550 MB)
docker compose up -d
```

Abre `http://<ip-del-servidor>:8099`.

- **Cambiar el puerto:** `CRAFT_PORT=9000 docker compose up -d`, o pon `CRAFT_PORT=9000` en un archivo `.env`.
- **Cambiar el nombre del contenedor** (por defecto `craftsuite`): `CRAFT_NAME=otra-suite` en el `.env`.
- **Solo algunas apps:** `docker compose run --rm -e CRAFT_APPS="pdfcraft wordcraft gridcraft" actualizar`. La página de inicio sigue mostrando las 13; las que no descargues dan 404.
- **Personalizar nombres e iconos:** crea `site/personalizar.json` (no se sube al repo), por ejemplo:
  `{"titulo":"Mi suite","apps":{"pdfcraft":{"nombre":"PDF","desc":"Leer y firmar PDF","icono":"mis-iconos/pdf.png"}}}`
- **Actualizar:** vuelve a lanzar `docker compose run --rm actualizar`. Solo descarga las apps que tengan versión nueva y no hace falta reiniciar nginx. Puedes programarlo, por ejemplo una vez por semana.

### Synology / Xpenology

Copia la carpeta a `/volume1/docker/craft-suite-docker` y, por SSH, lanza los mismos comandos. Si usas Portainer, crea un *stack* apuntando a este repositorio y lanza `actualizar` una vez a mano.

### Panel Homepage (opcional)

```yaml
- Suite digital:
    - PdfCraft:
        icon: http://IP:8099/icons/pdfcraft.png
        href: http://IP:8099/pdfcraft/?webgl
        description: "PDF · como Acrobat"
        server: my-docker
        container: craftsuite
```

## HTTPS (recomendado)

Por HTTP las apps funcionan, pero los navegadores solo activan **WebGPU** y el **portapapeles** en un contexto seguro (`https://` o `localhost`). Sin HTTPS, la página de inicio abre las apps con `?webgl` (WebGL2), porque en algunos navegadores el modo automático se queda con la pantalla en negro. Funciona bien, aunque va algo más lento en foto y vídeo. Si quieres HTTPS en la red local, pon delante un proxy inverso (Caddy, Nginx Proxy Manager, Traefik) con un certificado en el que confíen tus dispositivos.

## Limitaciones

- Las apps están en **alfa**. Para trabajos importantes, guarda a menudo.
- Los archivos se abren y se guardan con el selector de archivos y las descargas del navegador. No hay almacenamiento compartido en el servidor.
- **Sonido:** algunos navegadores dejan en pausa el audio que la app crea al arrancar. `actualizar.sh` añade a cada app un pequeño parche que lo reanuda con el primer clic o toque.
- **Firmar PDF:** PdfCraft web firma con un certificado en archivo (`.p12` / `.pfx`). Las tarjetas criptográficas (DNIe, tokens USB) no están disponibles desde el navegador.
- La impresión desde la versión web de PdfCraft todavía no está disponible.
- Solo se ha probado en redes locales. Si lo publicas en internet, protégelo con autenticación.

## Licencia

Este proyecto (configuración y scripts) se publica bajo la licencia MIT. Las apps son de [storytold/ArtCraft](https://github.com/storytold) y tienen su propia licencia (Apache-2.0 / MIT); se descargan de sus releases oficiales y no se redistribuyen en este repositorio. Este proyecto no está afiliado a ArtCraft ni a Adobe.
