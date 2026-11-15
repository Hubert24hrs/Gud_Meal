"""Neighbourhoods we serve, with approximate centre points.

Used to place an address when no map pin is available (manual address entry, the AI assistant, parcels).
Precision is about a kilometre, which is enough for pricing; riders navigate by the street address and phone.
Replaced by Google Maps geocoding once a Maps key is configured.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass

from .geo import GeoPoint


@dataclass(frozen=True, slots=True)
class Area:
    name: str
    city: str
    lat: float
    lng: float
    aliases: tuple[str, ...] = ()

    @property
    def location(self) -> GeoPoint:
        return GeoPoint(lat=self.lat, lng=self.lng)


AREAS: tuple[Area, ...] = (
    # ------------------------------------------------------------------------------------- Lagos Island
    Area("Victoria Island", "lagos", 6.4281, 3.4219, ("vi", "v.i", "v/i")),
    Area("Ikoyi", "lagos", 6.4520, 3.4350),
    Area("Oniru", "lagos", 6.4366, 3.4517),
    Area("Lekki Phase 1", "lagos", 6.4478, 3.4723, ("lekki phase one", "lekki 1", "phase 1")),
    Area("Agungi", "lagos", 6.4370, 3.5090),
    Area("Osapa London", "lagos", 6.4400, 3.5150, ("osapa",)),
    Area("Jakande", "lagos", 6.4430, 3.5170),
    Area("Chevron", "lagos", 6.4395, 3.5307, ("chevron drive",)),
    Area("Ikota", "lagos", 6.4510, 3.5480),
    Area("VGC", "lagos", 6.4720, 3.5600, ("victoria garden city",)),
    Area("Ajah", "lagos", 6.4682, 3.5852),
    Area("Badore", "lagos", 6.4880, 3.5980),
    Area("Sangotedo", "lagos", 6.4697, 3.6328),
    Area("Lagos Island", "lagos", 6.4541, 3.3947, ("marina", "isale eko", "idumota")),
    Area("Obalende", "lagos", 6.4480, 3.4060),
    # ------------------------------------------------------------------------------------- Lagos Mainland
    Area("Yaba", "lagos", 6.5095, 3.3711),
    Area("Akoka", "lagos", 6.5240, 3.3880, ("unilag",)),
    Area("Ebute Metta", "lagos", 6.4850, 3.3800, ("ebute-metta",)),
    Area("Surulere", "lagos", 6.4969, 3.3602),
    Area("Ojuelegba", "lagos", 6.5080, 3.3640),
    Area("Apapa", "lagos", 6.4489, 3.3590),
    Area("Festac Town", "lagos", 6.4660, 3.2830, ("festac",)),
    Area("Mushin", "lagos", 6.5300, 3.3500),
    Area("Ilupeju", "lagos", 6.5550, 3.3560),
    Area("Palmgrove", "lagos", 6.5450, 3.3700),
    Area("Anthony Village", "lagos", 6.5600, 3.3700, ("anthony",)),
    Area("Gbagada", "lagos", 6.5550, 3.3890),
    Area("Maryland", "lagos", 6.5700, 3.3670),
    Area("Ogudu", "lagos", 6.5770, 3.3920),
    Area("Ojota", "lagos", 6.5870, 3.3780),
    Area("Ketu", "lagos", 6.5950, 3.3880),
    Area("Magodo", "lagos", 6.6180, 3.3830),
    Area("Ikeja", "lagos", 6.6018, 3.3515, ("allen avenue", "computer village")),
    Area("Ikeja GRA", "lagos", 6.5833, 3.3500),
    Area("Ogba", "lagos", 6.6260, 3.3430),
    Area("Ojodu Berger", "lagos", 6.6400, 3.3700, ("ojodu", "berger")),
    Area("Agege", "lagos", 6.6200, 3.3200),
    Area("Oshodi", "lagos", 6.5550, 3.3430),
    Area("Isolo", "lagos", 6.5300, 3.3240),
    Area("Ikorodu", "lagos", 6.6194, 3.5105),
    # ------------------------------------------------------------------------------------- Enugu
    Area("Independence Layout", "enugu", 6.4473, 7.5214, ("independence",)),
    Area("Enugu GRA", "enugu", 6.4590, 7.5050, ("gra enugu",)),
    Area("New Haven", "enugu", 6.4400, 7.5150),
    Area("Trans-Ekulu", "enugu", 6.4840, 7.5160, ("trans ekulu", "ekulu")),
    Area("Thinkers Corner", "enugu", 6.4800, 7.5200),
    Area("Abakpa Nike", "enugu", 6.4950, 7.5300, ("abakpa",)),
    Area("Emene", "enugu", 6.4700, 7.5900),
    Area("Ogui", "enugu", 6.4410, 7.4960, ("ogui road",)),
    Area("Asata", "enugu", 6.4470, 7.4940),
    Area("Coal Camp", "enugu", 6.4380, 7.4880),
    Area("Uwani", "enugu", 6.4250, 7.4950),
    Area("Achara Layout", "enugu", 6.4180, 7.5060, ("achara",)),
    Area("Maryland Enugu", "enugu", 6.4200, 7.5100),
    Area("Agbani Road", "enugu", 6.4100, 7.5000),
    Area("Ugwuaji", "enugu", 6.4000, 7.5300),
)

_WORDS = re.compile(r"[a-z0-9]+")


def _norm(text: str) -> str:
    plain = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
    return " ".join(_WORDS.findall(plain))


def areas(city: str | None = None) -> list[Area]:
    return [a for a in AREAS if city is None or a.city == city]


def find_area(text: str, city: str | None = None) -> Area | None:
    """Best neighbourhood for free text such as '12 Admiralty Way, Lekki Phase 1' or 'yaba'."""
    q = _norm(text)
    if not q:
        return None
    best: tuple[int, Area] | None = None
    for area in areas(city):
        for name in (area.name, *area.aliases):
            n = _norm(name)
            if not n:
                continue
            if q == n:
                score = 1000 + len(n)
            elif re.search(rf"\b{re.escape(n)}\b", q):
                score = 100 + len(n)  # area named inside a longer address; prefer the most specific
            elif n.startswith(q) and len(q) >= 3:
                score = 10 + len(q)
            else:
                continue
            if best is None or score > best[0]:
                best = (score, area)
    return best[1] if best else None
