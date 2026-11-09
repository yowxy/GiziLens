"""Sumber tunggal daftar kelas GiziLens -> menghasilkan classes.json + gizilens.yaml.

Edit daftar di SPEC di bawah, lalu jalankan:  python build_classes.py [--out folder]

Format baris:  nama_kelas | prioritas | alias1, alias2, ...
  prioritas 1 = sangat umum di menu MBG   (latih dulu)
  prioritas 2 = umum
  prioritas 3 = jarang / khas daerah       (tambah belakangan saat data cukup)
alias (Inggris/Indonesia) dipakai merge_datasets.py untuk memetakan kelas dataset Roboflow otomatis.

PENTING: id = urutan baris. Setelah labeling dimulai, JANGAN menyisipkan/menghapus di tengah;
tambahkan kelas baru di PALING BAWAH tiap file (atau bagian terakhir).
"""
import argparse
import json
import re
from collections import Counter
from pathlib import Path

SPEC = """
[wadah]
ompreng | 1 | tray, food tray, meal tray, lunch tray

[karbohidrat]
nasi_putih | 1 | rice, nasi, steamed rice, cooked rice, white rice
nasi_merah | 2 | brown rice, red rice
nasi_kuning | 2 | yellow rice, tumpeng
nasi_uduk | 2 | coconut rice
nasi_goreng | 2 | fried rice
bubur_nasi | 2 | rice porridge, bubur, porridge, congee
lontong | 2 | compressed rice, rice cake
ketupat | 3 |
mie_goreng | 2 | fried noodle, fried noodles, mi goreng
mie_kuah | 2 | noodle soup, mie rebus, mie ayam, noodles, noodle
bihun | 2 | vermicelli, rice vermicelli, bihun goreng
kwetiau | 3 | flat noodle, kway teow
makaroni | 3 | macaroni, pasta, spaghetti
kentang_rebus | 2 | boiled potato, potato, potatoes
kentang_goreng | 2 | french fries, fries
kentang_tumbuk | 3 | mashed potato
ubi_jalar | 2 | sweet potato, ubi, ubi rebus
singkong_rebus | 2 | cassava, boiled cassava, singkong
singkong_goreng | 3 | fried cassava
jagung_rebus | 2 | corn, boiled corn, jagung, corn on the cob
talas | 3 | taro
roti_tawar | 2 | bread, white bread, roti, toast
roti_isi | 3 | filled bun, roti manis, sweet bun
oatmeal | 3 | oat, oats
papeda | 3 |
lemper | 3 |
arem_arem | 3 |
getuk | 3 |
tiwul | 3 |

[lauk_hewani]
ayam_goreng | 1 | fried chicken, chicken, ayam
ayam_bakar | 1 | grilled chicken, roast chicken, ayam panggang
ayam_kecap | 2 | soy sauce chicken, ayam semur, semur ayam
ayam_kuah | 2 | chicken curry, opor ayam, opor, gulai ayam, chicken stew
ayam_suwir | 2 | shredded chicken
ayam_geprek | 2 | smashed chicken
ayam_tepung | 2 | crispy chicken, chicken katsu, ayam crispy, ayam katsu, chicken tenders
ayam_rebus | 3 | boiled chicken, ayam rebus
ayam_balado | 3 | ayam rica rica, ayam woku
nugget_ayam | 1 | chicken nugget, nugget, chicken nuggets
sate_ayam | 2 | chicken satay, satay, sate
sosis | 2 | sausage, sausages
bakso | 1 | meatball, meatballs
daging_sapi | 2 | beef, beef steak, daging
rendang | 2 | beef rendang
semur_daging | 2 | beef stew
empal | 3 | empal gepuk
dendeng | 3 | beef jerky, jerky
abon | 3 | meat floss, shredded meat floss
kornet | 3 | corned beef
daging_kambing | 3 | mutton, goat meat, lamb
hati_ayam | 3 | chicken liver, ati ampela, ampela
telur_rebus | 1 | boiled egg, hard boiled egg, telur, egg, eggs, telor, telor rebus
telur_dadar | 1 | omelette, omelet, telur dadar, telor dadar
telur_ceplok | 1 | fried egg, sunny side up, telur mata sapi, telor mata sapi, telor ceplok
telur_balado | 2 | egg balado, telur bumbu, telor balado
telur_semur | 2 | egg stew, telur kecap
telur_orak_arik | 3 | scrambled egg, scrambled eggs
telur_asin | 3 | salted egg
telur_puyuh | 3 | quail egg
ikan_goreng | 1 | fried fish, fish, ikan
ikan_bakar | 2 | grilled fish
ikan_kuah | 3 | fish curry, pindang, ikan pindang, gulai ikan, fish soup
ikan_saus | 3 | sweet sour fish, ikan asam manis, fish with sauce
ikan_pepes | 3 | pepes ikan, steamed fish
lele_goreng | 2 | catfish, fried catfish, pecel lele, lele
nila_goreng | 2 | tilapia, fried tilapia, nila
bandeng | 2 | milkfish
kembung | 2 | mackerel, ikan kembung
tongkol | 3 | tuna, skipjack, ikan tongkol
patin | 3 | pangasius
salmon | 3 |
teri | 3 | anchovy, ikan teri, teri goreng, ikan asin, salted fish
udang | 2 | shrimp, prawn, udang goreng
cumi | 3 | squid, calamari, cumi goreng
siomay | 3 | dumpling, shumai, dimsum, dim sum
otak_otak | 3 |
pempek | 3 | empek empek
martabak_telur | 3 | martabak telor, martabak, egg martabak
soto | 3 | soto ayam, soto betawi, chicken soup

[lauk_nabati]
tempe_goreng | 1 | fried tempeh, tempeh, tempe
tempe_bacem | 2 | sweet tempeh, tempe kecap
tempe_orek | 2 | stir fried tempeh, tempe sambal
tempe_mendoan | 2 | tempe tepung, battered tempeh
tahu_goreng | 1 | fried tofu, tofu, tahu
tahu_bacem | 2 | braised tofu, tahu kecap
tahu_isi | 3 | stuffed tofu
tahu_rebus | 3 | boiled tofu, tahu putih, silken tofu, white tofu
tahu_krispi | 3 | crispy tofu, tahu crispy
tahu_balado | 3 | tahu bumbu, tahu sambal
perkedel_kentang | 2 | potato patty, perkedel, potato croquette
perkedel_jagung | 3 | corn fritter
bakwan | 3 | vegetable fritter, bala bala, fritters
oncom | 3 |
kacang_tanah | 3 | peanut, peanuts
kacang_merah | 3 | kidney beans, red beans
edamame | 3 |

[sayur]
sayur_lain | 1 | sayur, vegetable, vegetables, veggies, sayuran, sayur campur
sayur_sop | 1 | vegetable soup, sop, sup sayur, sup, soup
sayur_bening | 1 | clear soup, sayur bayam, bayam bening, clear vegetable soup
sayur_asem | 2 | sour vegetable soup, sayur asam
sayur_lodeh | 2 | coconut vegetable curry
capcay | 1 | cap cay, chop suey, stir fried mixed vegetables, mixed vegetables
tumis_kangkung | 1 | stir fried water spinach, kangkung tumis
tumis_buncis | 2 | stir fried green beans
tumis_sawi | 2 | stir fried mustard greens, tumis pakcoy
tumis_tauge | 2 | stir fried bean sprouts, orek tauge
tumis_wortel | 2 | stir fried carrot
tumis_kol | 2 | stir fried cabbage, tumis kubis
tumis_brokoli | 2 | stir fried broccoli, cah brokoli
tumis_kacang_panjang | 2 | stir fried long beans
tumis_jamur | 3 | stir fried mushroom
tumis_labu_siam | 3 | stir fried chayote
urap | 2 | urap sayur, vegetables with grated coconut
pecel | 2 | pecel sayur
gado_gado | 2 | gado gado, indonesian salad
karedok | 3 |
salad_sayur | 2 | salad, green salad, mixed salad, coleslaw
lalapan | 1 | fresh vegetables, raw vegetables, lalap
sayur_nangka | 3 | gudeg, young jackfruit curry, gulai nangka
sayur_labu | 3 | pumpkin soup, sayur labu siam
wortel | 2 | carrot, carrots
tomat | 1 | tomato, tomatoes
timun | 1 | cucumber, mentimun, cucumbers
selada | 1 | lettuce, salad leaf, romaine
kol | 2 | cabbage, kubis
kembang_kol | 3 | cauliflower
brokoli | 2 | broccoli
bayam | 2 | spinach
kangkung | 2 | water spinach, kangkong, morning glory, swamp cabbage
sawi_hijau | 2 | mustard greens, choy sum, caisim, sawi, mustard green
pakcoy | 2 | bok choy, pak choi, pakchoi
buncis | 2 | green beans, string beans, french beans
kacang_panjang | 2 | long beans, yardlong bean, snake beans
tauge | 2 | bean sprouts, beansprouts, kecambah, mung bean sprouts
labu_siam | 3 | chayote
labu_kuning | 3 | pumpkin, squash, butternut
terong | 2 | eggplant, aubergine, brinjal
jamur | 2 | mushroom, mushrooms
paprika | 3 | bell pepper, capsicum
pare | 3 | bitter gourd, bitter melon
gambas | 3 | luffa, oyong, sponge gourd
okra | 3 |
rebung | 3 | bamboo shoots
daun_singkong | 3 | cassava leaves
daun_pepaya | 3 | papaya leaves
kemangi | 3 | basil, thai basil
daun_bawang | 3 | spring onion, scallion, green onion, leek
seledri | 3 | celery
lobak | 3 | radish, daikon
bit | 3 | beetroot, beet

[buah]
pisang | 1 | banana, bananas, pisang ambon, pisang kepok
jeruk | 1 | orange, oranges, mandarin, tangerine, jeruk keprok, jeruk manis
apel | 1 | apple, apples
pepaya | 1 | papaya, pawpaw
semangka | 1 | watermelon
melon | 1 | honeydew, rockmelon
salak | 2 | snake fruit, snakefruit
mangga | 2 | mango, mangoes
nanas | 2 | pineapple
jambu_biji | 2 | guava
anggur | 2 | grape, grapes
pir | 2 | pear
alpukat | 2 | avocado
buah_naga | 2 | dragon fruit, pitaya, dragonfruit
jambu_air | 3 | water apple, wax apple, rose apple
kiwi | 3 |
stroberi | 3 | strawberry
belimbing | 3 | starfruit, star fruit, carambola
manggis | 3 | mangosteen
rambutan | 3 |
lengkeng | 3 | longan
durian | 3 |
nangka | 3 | jackfruit
cempedak | 3 |
sirsak | 3 | soursop, graviola
markisa | 3 | passion fruit
duku | 3 | langsat, lansium
sawo | 3 | sapodilla
kedondong | 3 | ambarella, hog plum
delima | 3 | pomegranate
blewah | 3 | cantaloupe, muskmelon
jeruk_bali | 3 | pomelo
lemon | 3 | lime, jeruk nipis
kurma | 3 | dates, date fruit
blueberry | 3 |
kelapa_muda | 3 | young coconut, coconut
leci | 3 | lychee, litchi
ceri | 3 | cherry, cherries

[susu]
susu_kotak | 1 | uht milk, milk carton, milk box, susu uht, milk, carton milk
susu_botol | 2 | milk bottle, bottled milk
susu_gelas | 2 | milk cup, milk glass, glass of milk, susu cair
susu_coklat | 2 | chocolate milk
susu_kedelai | 2 | soy milk, soymilk
yogurt | 1 | yoghurt, yogurt cup
yogurt_drink | 2 | drinking yogurt, yakult, probiotic drink, minuman yogurt
keju | 2 | cheese, cheese slice
susu_kental_manis | 3 | condensed milk, sweet condensed milk
kefir | 3 |
puding_susu | 3 | milk pudding
es_krim | 3 | ice cream
dadih | 3 |
dangke | 3 |
susu_kambing | 3 | goat milk

[pelengkap]
kerupuk | 1 | cracker, crackers, prawn cracker, krupuk
sambal | 2 | sambel, chili sauce, sambal terasi, sambal sauce, chilli sauce, chili paste
acar | 2 | pickles, pickled vegetables, pickle
saus | 3 | sauce, ketchup, tomato sauce, mayonnaise
kecap | 3 | soy sauce
emping | 3 |
keripik_tempe | 3 | tempeh chips
rempeyek | 3 |
bawang_goreng | 3 | fried shallot, fried onion
cabai | 3 | chili, chilli, red chili, cabe, chili pepper
puding | 2 | pudding, custard, jelly, agar agar, agar-agar, jelly dessert
bubur_kacang_hijau | 2 | mung bean porridge, green bean porridge
kue_basah | 2 | traditional cake, kue, cake, wet cake
bolu | 2 | sponge cake, bolu kukus, steamed cake, muffin, cupcake
biskuit | 2 | biscuit, cookie, cookies, biscuits
pisang_goreng | 3 | fried banana
lumpia | 3 | spring roll, spring rolls, egg roll
risoles | 3 | rissole
pastel | 3 | fried pastry
dadar_gulung | 3 | rolled pancake
klepon | 3 |
onde_onde | 3 |
kue_lapis | 3 | layer cake
# ---- Kelas "lain": penampung label kasar dari dataset yang hanya bilang "buah", "nasi", dst. ----
# Ditaruh paling bawah agar id kelas lain tidak bergeser. Gizi/berat memakai rata-rata kelompok.
[buah]
buah_lain | 1 | buah, buah buahan, fruit, fruits
[lauk_hewani]
lauk_hewani_lain | 1 | lauk hewani, protein hewani, hewani, meat, animal protein
[lauk_nabati]
lauk_nabati_lain | 1 | lauk nabati, protein nabati, nabati, plant protein
[karbohidrat]
karbohidrat_lain | 1 | karbohidrat, karbo, carb, carbs, staple, makanan pokok
[susu]
susu_lain | 2 | susu, dairy, minuman susu
[pelengkap]
pelengkap_lain | 2 | pelengkap, side, sides, snack, jajanan
[wadah]

# ---- Ditambahkan dari kebutuhan dataset (id baru di paling bawah) ----
[karbohidrat]
mie | 2 | mi, noodle mie
[lauk_nabati]
kedelai | 3 | soybean, soybeans, soy bean, soya
[sayur]
bawang_bombay | 3 | onion, onions, bawang, red onion, white onion
kacang_polong | 3 | peas, pea, green peas, green pea
garlic | 3 | bawang putih, bawang putih geprek, bawang putih cincang
[pelengkap]
jahe | 3 | ginger
"""



def norm(s):
    return re.sub(r"[\s_\-]+", " ", s.strip().lower())


def parse(spec):
    classes, group = [], None
    for ln in spec.splitlines():
        ln = ln.strip()
        if not ln or ln.startswith("#"):
            continue
        if ln.startswith("["):
            group = ln.strip("[]")
            continue
        parts = [p.strip() for p in ln.split("|")]
        name, prio = parts[0], int(parts[1])
        aliases = [a.strip() for a in parts[2].split(",") if a.strip()] if len(parts) > 2 else []
        assert re.fullmatch(r"[a-z0-9_]+", name), f"nama tidak valid: {name}"
        classes.append({"id": len(classes), "name": name, "kelompok": group,
                        "prioritas": prio, "aliases": aliases})
    return classes


def validate(classes):
    names = [c["name"] for c in classes]
    dup = [n for n, k in Counter(names).items() if k > 1]
    if dup:
        raise SystemExit(f"Nama kelas duplikat: {dup}")
    seen = {}
    for c in classes:
        for k in [c["name"]] + c["aliases"]:
            n = norm(k)
            if n in seen and seen[n] != c["name"]:
                raise SystemExit(f"Alias '{k}' ({c['name']}) bentrok dengan kelas '{seen[n]}'")
            seen[n] = c["name"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(Path(__file__).resolve().parent))
    a = ap.parse_args()
    classes = parse(SPEC)
    validate(classes)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)

    with open(out / "classes.json", "w", encoding="utf-8") as f:
        json.dump({"_catatan": "Dibuat oleh build_classes.py - jangan edit manual.",
                   "classes": classes}, f, ensure_ascii=False, indent=1)

    with open(out / "gizilens.yaml", "w", encoding="utf-8") as f:
        f.write("# Dibuat oleh build_classes.py - jangan edit manual.\n")
        f.write("path: ./dataset\ntrain: images/train\nval: images/val\ntest: images/test\n\nnames:\n")
        last = None
        for c in classes:
            if c["kelompok"] != last:
                f.write(f"  # {c['kelompok']}\n")
                last = c["kelompok"]
            f.write(f"  {c['id']}: {c['name']}\n")

    print(f"{len(classes)} kelas -> {out}/classes.json, gizilens.yaml")
    byg, byp = Counter(c["kelompok"] for c in classes), Counter(c["prioritas"] for c in classes)
    print("per kelompok :", dict(byg))
    print("per prioritas:", dict(sorted(byp.items())))


if __name__ == "__main__":
    main()