/**
 * Original Yummy Chops illustrations (SVG, 100×100 design space). Shared look with the mobile app's painters.
 * No third-party artwork.
 */
import type { SVGProps } from "react";

type ArtProps = SVGProps<SVGSVGElement> & { title?: string };

function Svg({ title, children, ...rest }: ArtProps & { children: React.ReactNode }) {
  return (
    <svg viewBox="0 0 100 100" role={title ? "img" : "presentation"} aria-hidden={title ? undefined : true} {...rest}>
      {title ? <title>{title}</title> : null}
      {children}
    </svg>
  );
}

const grains = [
  [26, 44], [33, 48], [41, 43], [47, 50], [55, 45], [62, 49], [69, 44], [74, 50], [37, 52], [58, 52],
  [30, 50], [66, 53], [45, 46], [52, 42], [72, 47],
];

/** A bowl of smoky jollof with a drumstick, dodo and a sprig of green. */
export function FoodArt(props: ArtProps) {
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-bowl" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" stopColor="#EF6E3E" />
          <stop offset="1" stopColor="#B3050B" />
        </linearGradient>
        <linearGradient id="gm-drum" x1="0" x2="1">
          <stop offset="0" stopColor="#B4561F" />
          <stop offset="1" stopColor="#7A3512" />
        </linearGradient>
      </defs>
      <ellipse cx="50" cy="86" rx="33" ry="4" fill="#000" opacity=".12" />
      <path d="M40 24c-6-6 6-11 0-18M56 24c-6-6 6-11 0-18" stroke="#D9CFC4" strokeWidth="3" fill="none" strokeLinecap="round" />
      <path d="M16 56C18 30 82 30 84 56Z" fill="#E2622C" />
      {grains.map(([x, y], i) => (
        <rect key={i} x={x - 2.2} y={y - 0.9} width="4.4" height="1.8" rx="1" fill="#F08A4B" transform={`rotate(${(i * 37) % 180} ${x} ${y})`} />
      ))}
      {[
        [28, 44, -23],
        [36, 40, 11],
        [24, 37, 34],
      ].map(([x, y, a], i) => (
        <ellipse key={i} cx={x} cy={y} rx="5.5" ry="3.5" fill="#F5A21A" stroke="#B8741C" strokeWidth="1.4" transform={`rotate(${a} ${x} ${y})`} />
      ))}
      <g transform="translate(63 40) rotate(-31)">
        <rect x="-12" y="-7" width="22" height="14" rx="7" fill="url(#gm-drum)" />
        <rect x="9" y="-2" width="9" height="4" fill="#F7EBDD" />
        <circle cx="19" cy="-2.5" r="3" fill="#F7EBDD" />
        <circle cx="19" cy="2.5" r="3" fill="#F7EBDD" />
      </g>
      <ellipse cx="46" cy="33" rx="2.5" ry="6" fill="#2E8B57" transform="rotate(-34 46 33)" />
      <ellipse cx="51" cy="33" rx="2.5" ry="6" fill="#2E8B57" transform="rotate(29 51 33)" />
      <path d="M12 55H88C86 74 70 86 50 86S14 74 12 55Z" fill="url(#gm-bowl)" />
      <rect x="10" y="52" width="80" height="7" rx="4" fill="#F5A21A" />
      {[30, 50, 70].map((x) => (
        <circle key={x} cx={x} cy="70" r="3.2" fill="none" stroke="#fff" strokeOpacity=".4" strokeWidth="2" />
      ))}
    </Svg>
  );
}

/** Supplements & Skin Care: a cream jar, a serum dropper and a tub of supplements with a capsule, with sparkles. */
export function BeautyArt(props: ArtProps) {
  const sparkle = (x: number, y: number, r: number) =>
    `M${x} ${y - r}Q${x} ${y} ${x + r} ${y}Q${x} ${y} ${x} ${y + r}Q${x} ${y} ${x - r} ${y}Q${x} ${y} ${x} ${y - r}Z`;
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-serum" x1="0" x2="1">
          <stop offset="0" stopColor="#D9893A" />
          <stop offset="1" stopColor="#A85A1A" />
        </linearGradient>
        <linearGradient id="gm-lid" x1="0" x2="1">
          <stop offset="0" stopColor="#F59AA8" />
          <stop offset="1" stopColor="#E06A7E" />
        </linearGradient>
        <linearGradient id="gm-tub" x1="0" x2="1">
          <stop offset="0" stopColor="#FFFFFF" />
          <stop offset="1" stopColor="#E6EEF2" />
        </linearGradient>
      </defs>
      <ellipse cx="52" cy="88" rx="35" ry="4" fill="#000" opacity=".12" />
      <path d={sparkle(18, 22, 6)} fill="#F5A21A" />
      <path d={sparkle(86, 18, 4.5)} fill="#F5A21A" />
      <path d={sparkle(30, 10, 3)} fill="#F5A21A" />
      <rect x="44" y="30" width="18" height="6" rx="2" fill="#2B2B2B" />
      <rect x="47" y="16" width="12" height="16" rx="6" fill="#3A3A3A" />
      <rect x="41" y="36" width="24" height="46" rx="7" fill="url(#gm-serum)" />
      <rect x="45" y="52" width="16" height="14" rx="3" fill="#FDF1D6" />
      <rect x="44" y="40" width="4" height="34" rx="2" fill="#fff" opacity=".25" />
      <rect x="10" y="56" width="36" height="30" rx="8" fill="#FFF7F0" stroke="#EBD8C8" strokeWidth="1.6" />
      <rect x="8" y="47" width="40" height="12" rx="5" fill="url(#gm-lid)" />
      <rect x="14" y="66" width="28" height="10" rx="3" fill="#FDE7E6" />
      <circle cx="28" cy="71" r="3" fill="#E0040B" />
      <rect x="66" y="50" width="24" height="36" rx="6" fill="url(#gm-tub)" stroke="#D3DEE4" strokeWidth="1.4" />
      <rect x="68" y="43" width="20" height="9" rx="2.5" fill="#1F9D63" />
      <rect x="69" y="59" width="18" height="17" rx="3" fill="#E6F6EE" />
      <path d="M78 72Q71 67 78 62Q85 67 78 72Z" fill="#1F9D63" />
      <g transform="translate(89 33) rotate(-32)">
        <rect x="-8" y="-3.5" width="16" height="7" rx="3.5" fill="#FFF7F0" />
        <path d="M0-3.5H-4.5A3.5 3.5 0 0 0-4.5 3.5H0Z" fill="#E0040B" />
        <rect x="-8" y="-3.5" width="16" height="7" rx="3.5" fill="none" stroke="#000" strokeOpacity=".2" strokeWidth=".8" />
      </g>
    </Svg>
  );
}

/** A delivery scooter carrying a Yummy Chops parcel box. */
export function ParcelArt(props: ArtProps) {
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-scooter" x1="0" x2="1">
          <stop offset="0" stopColor="#F0262B" />
          <stop offset="1" stopColor="#3A0D05" />
        </linearGradient>
      </defs>
      <ellipse cx="52" cy="88" rx="36" ry="3.5" fill="#000" opacity=".12" />
      <path d="M2 58h10M2 66h14M2 74h9" stroke="#D9CFC4" strokeWidth="3" strokeLinecap="round" />
      <rect x="16" y="24" width="34" height="32" rx="4" fill="#E4AB6E" stroke="#B4743A" strokeWidth="1.4" />
      <rect x="30" y="24" width="6" height="32" fill="#C98A4B" />
      <circle cx="23" cy="47" r="3.4" fill="#E0040B" />
      <path d="M14 62H60Q70 62 74 70L80 72H18Q12 70 14 62Z" fill="url(#gm-scooter)" />
      <rect x="34" y="54" width="24" height="7" rx="3.5" fill="#2B2B2B" />
      <path d="M70 66L80 32" stroke="#3A0D05" strokeWidth="5" strokeLinecap="round" />
      <path d="M74 31H88" stroke="#2B2B2B" strokeWidth="4" strokeLinecap="round" />
      <circle cx="84" cy="40" r="3" fill="#F5A21A" />
      {[26, 76].map((x) => (
        <g key={x}>
          <circle cx={x} cy="78" r="10" fill="#2B2B2B" />
          <circle cx={x} cy="78" r="4" fill="#C8C8C8" />
        </g>
      ))}
    </Svg>
  );
}

/** Yummy, the Yummy Chops AI assistant: a friendly robot in a disc of the logo's chocolate brown (the cloche), with a gold antenna and a chat-bubble tail. */
export function GudyArt({ blink = false, ...props }: ArtProps & { blink?: boolean }) {
  return (
    <Svg {...props}>
      <defs>
        <radialGradient id="gm-gudy" cx=".35" cy=".3" r=".9">
          <stop offset="0" stopColor="#B4561F" />
          <stop offset=".55" stopColor="#6B2410" />
          <stop offset="1" stopColor="#3A0D05" />
        </radialGradient>
      </defs>
      <circle cx="50" cy="50" r="50" fill="url(#gm-gudy)" />
      <path d="M50 31V21" stroke="#fff" strokeWidth="3.4" strokeLinecap="round" />
      <circle cx="50" cy="18.5" r="4.6" fill="#F5A21A" />
      <rect x="19" y="44" width="8" height="15" rx="4" fill="#F6DCC6" />
      <rect x="73" y="44" width="8" height="15" rx="4" fill="#F6DCC6" />
      <path d="M42 31H58A17 17 0 0 1 75 48V52A17 17 0 0 1 58 69H50L33 78L36 65A17 17 0 0 1 25 52V48A17 17 0 0 1 42 31Z" fill="#fff" />
      <rect x="32" y="40" width="36" height="19" rx="9.5" fill="#6B2410" />
      <g className={blink ? "gm-blink" : undefined} style={{ transformOrigin: "50px 49.5px" }}>
        <ellipse cx="42" cy="49.5" rx="4.2" ry="4.2" fill="#fff" />
        <ellipse cx="58" cy="49.5" rx="4.2" ry="4.2" fill="#fff" />
      </g>
    </Svg>
  );
}
