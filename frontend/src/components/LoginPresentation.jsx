import { useEffect, useRef, useState } from "react";
import { ArrowRight, ArrowUpRight, CalendarDays, ChevronDown, ChevronLeft, ChevronRight, MapPin, Menu, Pause, Play, ShieldCheck, TentTree, X } from "lucide-react";
import "./LoginPresentation.css";

const slides = [
  { image: "/images/espacios/campo-demo.png", title: "Aventuras que nos conectan", text: "Un espacio para aprender, compartir y disfrutar al aire libre.", alt: "Campamento entre árboles y montañas" },
  { image: "/images/espacios/sede-demo.png", title: "Encuentros con propósito", text: "Planea reuniones y actividades para seguir construyendo comunidad.", alt: "Edificio rodeado de jardines tropicales" },
  { image: "/images/espacios/centro-demo.png", title: "Más momentos para compartir", text: "Encuentra el lugar para tu próxima actividad.", alt: "Salón abierto con mesas y un jardín" }
];
const locations = [
  { name: "Campo Escuela Nacional Iztarú", location: "Cartago", type: "Campo escuela", image: slides[0].image },
  { name: "Campo Escuela Nacional Yörí", location: "Sarapiquí, Heredia", type: "Campo escuela", image: slides[0].image },
  { name: "Sede Nacional", location: "San Vicente, Moravia", type: "Sede institucional", image: slides[1].image }
];
function Instagram() { return <svg width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5" /><circle cx="12" cy="12" r="4" /><circle cx="17.5" cy="6.5" r="1" fill="currentColor" stroke="none" /></svg>; }
function Youtube() { return <svg width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><rect x="2" y="5" width="20" height="14" rx="4" /><path d="m10 9 5 3-5 3Z" fill="currentColor" stroke="none" /></svg>; }
function Facebook() { return <svg width="21" height="21" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M14 22v-9h3l.5-4H14V7c0-1.2.4-2 2-2h2V1.4A22 22 0 0 0 15 1c-3 0-5 1.9-5 5.3V9H7v4h3v9Z" /></svg>; }
const social = [
  { name: "Instagram", href: "https://www.instagram.com/guiasyscoutscr/", icon: Instagram },
  { name: "YouTube", href: "https://www.youtube.com/@guiasyscoutsdecostarica8833", icon: Youtube },
  { name: "Facebook", href: "https://www.facebook.com/GuiasyScoutsCR", icon: Facebook }
];
function SocialLinks() {
  return <div className="public-social-links">{social.map(({ name, href, icon: Icon }) => <a key={name} href={href} target="_blank" rel="noopener noreferrer"><Icon size={21} /><span>{name}</span></a>)}<a href="https://www.tiktok.com/@guiasyscoutscr" target="_blank" rel="noopener noreferrer"><span className="public-tiktok" aria-hidden="true">♪</span><span>TikTok</span></a></div>;
}
function SiteLinks() {
  return <><a href="#inicio">Inicio</a><a href="#lugares">Espacios</a><a href="#comunidad">Comunidad</a></>;
}
export default function LoginPresentation({ children }) {
  const dialogRef = useRef(null);
  const [accessOpen, setAccessOpen] = useState(false);
  useEffect(() => {
    const dialog = dialogRef.current;
    if (accessOpen) {
      dialog.showModal();
      const overflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
      return () => { document.body.style.overflow = overflow; };
    }
    dialog.close();
  }, [accessOpen]);
  const [slide, setSlide] = useState(0);
  const [playing, setPlaying] = useState(() => !window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  const [hovering, setHovering] = useState(false);
  useEffect(() => {
    if (!playing || hovering) return;
    const timer = window.setInterval(() => setSlide(current => (current + 1) % slides.length), 6500);
    return () => window.clearInterval(timer);
  }, [playing, hovering]);
  const current = slides[slide];
  return (
    <div className="public-login" id="inicio" onClick={event => {
      if (event.target.closest('a[href="#acceso"]')) {
        event.preventDefault();
        setAccessOpen(true);
      }
    }}>
      <a className="public-skip" href="#acceso">Ir al inicio de sesión</a>
      <header className="public-header">
        <div className="public-header-main">
          <a href="#inicio" className="public-brand" aria-label="Reservas Scouts, inicio"><span className="public-brand-mark"><TentTree size={29} /></span><span><strong>Reservas</strong><small>SCOUTS · COSTA RICA</small></span></a>
          <nav className="public-desktop-nav" aria-label="Navegación de bienvenida"><SiteLinks /></nav>
          <div className="public-header-actions">
            <details className="public-mobile-menu"><summary><Menu size={19} />Menú<ChevronDown size={14} /></summary><nav aria-label="Menú de bienvenida" onClick={event => { if (event.target.closest("a")) event.currentTarget.closest("details").open = false; }}><SiteLinks /></nav></details>
            <a className="public-signin" href="#acceso">Iniciar sesión<ArrowUpRight size={15} /></a>
          </div>
        </div>
        <div className="public-ribbon"><div><span>SIEMPRE LISTOS</span><p>Para el próximo encuentro, para la próxima aventura.</p></div><a href="https://siemprelistos.com/" target="_blank" rel="noopener noreferrer">Visitar siemprelistos.com<ArrowUpRight size={14} /></a></div>
      </header>
      <main>
        <section className="public-hero" aria-labelledby="public-title">
          <div className="public-hero-copy">
            <p className="public-eyebrow"><span />UN LUGAR PARA CADA ENCUENTRO</p>
            <h1 id="public-title">Las mejores<br />aventuras<br />empiezan <em>aquí.</em></h1>
            <p className="public-hero-description">Encuentra un espacio, consulta su disponibilidad y organiza tu próxima actividad. Más tiempo para compartir, todo en un mismo lugar.</p>
            <div className="public-hero-actions"><a className="public-primary" href="#lugares">Explorar espacios<ArrowRight size={18} /></a><a className="public-text-link" href="#acceso">Ya tengo una cuenta<ArrowUpRight size={16} /></a></div>
            <div className="public-hero-note"><span><CalendarDays size={16} />Consulta disponibilidad</span><span><ShieldCheck size={16} />Da seguimiento a tu reserva</span></div>
          </div>
          <div className="public-hero-gallery" aria-label="Galería de bienvenida" aria-roledescription="carrusel" onMouseEnter={() => setHovering(true)} onMouseLeave={() => setHovering(false)} onFocus={() => setHovering(true)} onBlur={event => { if (!event.currentTarget.contains(event.relatedTarget)) setHovering(false); }}>
            <div className="public-photo"><img src={current.image} alt={current.alt} fetchPriority="high" /><div className="public-photo-shade" /><div className="public-photo-top"><span><TentTree size={14} />EXPLORA · CONECTA · COMPARTE</span><span>0{slide + 1} / 03</span></div><div className="public-photo-caption"><h2>{current.title}</h2><p>{current.text}</p></div><div className="public-photo-arrows"><button type="button" aria-label="Imagen anterior" onClick={() => setSlide((slide + slides.length - 1) % slides.length)}><ChevronLeft size={20} /></button><button type="button" aria-label="Siguiente imagen" onClick={() => setSlide((slide + 1) % slides.length)}><ChevronRight size={20} /></button></div></div>
            <div className="public-gallery-bottom"><span>ESPACIOS QUE INSPIRAN</span><div className="public-gallery-dots">{slides.map((item, index) => <button key={item.image} type="button" aria-label={`Mostrar imagen ${index + 1}`} aria-pressed={slide === index} onClick={() => setSlide(index)} />)}<button className="public-play" type="button" aria-label={playing ? "Pausar carrusel" : "Reproducir carrusel"} onClick={() => setPlaying(!playing)}>{playing ? <Pause size={13} /> : <Play size={13} />}</button></div></div>
          </div>
        </section>
        <section className="public-locations" id="lugares" aria-labelledby="public-locations-title">
          <div className="public-section-heading"><div><p className="public-eyebrow">DESCUBRE TU PRÓXIMO DESTINO</p><h2 id="public-locations-title">Espacios para hacer comunidad.</h2></div><a className="public-text-link" href="#acceso">Ingresa para ver el catálogo<ArrowUpRight size={17} /></a></div>
          <div className="public-location-grid">{locations.map(place => <a className="public-location" key={place.name} href="#acceso"><div><img src={place.image} alt="" loading="lazy" /><span><ArrowUpRight size={20} /></span></div><p>{place.type}</p><h3>{place.name}</h3><small><MapPin size={14} />{place.location}</small></a>)}</div>
        </section>

      </main>
      <dialog ref={dialogRef} className="public-auth-dialog" aria-label="Acceso a Reservas Scouts" onCancel={() => setAccessOpen(false)} onClose={() => setAccessOpen(false)} onClick={event => { if (event.target === event.currentTarget) setAccessOpen(false); }}>
        <div className="public-access">
          <button className="public-auth-close" type="button" aria-label="Cerrar inicio de sesión" onClick={() => setAccessOpen(false)}><X size={20} /></button>
          {children}
        </div>
      </dialog>
      <section id="comunidad" className="public-community" aria-labelledby="public-community-title"><div><p className="public-eyebrow">GUÍAS Y SCOUTS DE COSTA RICA</p><h2 id="public-community-title">La aventura continúa<br />fuera de aquí.</h2><p>Conoce sus actividades, noticias y comunidad.</p></div><SocialLinks /></section>
      <footer className="public-footer"><span>Reservas Scouts</span><p>Encuentra tu lugar. Comparte la experiencia.</p><a href="#inicio">Volver arriba ↑</a></footer>
    </div>
  );
}
