import { useState, useMemo, useEffect } from "react";
import {
  LayoutDashboard, Users, Wifi, MapPin,
  ChevronRight, Search, Menu, X, Bell,
  TrendingUp, TrendingDown, Signal, SunMedium, MoonStar,
} from "lucide-react";

const BRAND = {
  maroon: "#8B1E3D",
  blue: "#0B3F75",
  cyan: "#2FA6D9",
  teal: "#3AA9A5",
  gold: "#E7A83D",
  slate: "#F3F4F2",
  ink: "#1E2330",
};

const logoUrl = new URL("../assets/comsys-logo.png", import.meta.url).href;

const CLIENTS = [
  { id: 1,  accountNo: "CGH-001", company: "Ghana Commercial Bank",   contactName: "Kwame Asante",      phone: "0302-740200", email: "kwame.asante@gcb.com.gh",        region: "Greater Accra", address: "Thorpe Road, High Street, Accra",           type: "Enterprise",  serviceType: "Leased Line", bandwidth: "1 Gbps",    monthlyFee: 45000, contractStart: "2023-01-01", contractEnd: "2025-12-31", status: "Active",    sites: 8  },
  { id: 2,  accountNo: "CGH-002", company: "Stanbic Bank Ghana",      contactName: "Abena Owusu",       phone: "0302-610220", email: "a.owusu@stanbicbank.com.gh",      region: "Greater Accra", address: "Stanbic Heights, Airport City, Accra",     type: "Enterprise",  serviceType: "MPLS",        bandwidth: "500 Mbps",  monthlyFee: 32000, contractStart: "2022-06-15", contractEnd: "2025-06-14", status: "Active",    sites: 5  },
  { id: 3,  accountNo: "CGH-003", company: "Tullow Oil Ghana",        contactName: "Kofi Mensah",       phone: "0302-550100", email: "k.mensah@tullowoil.com",          region: "Greater Accra", address: "28 Labone Close, Accra",                   type: "Enterprise",  serviceType: "MPLS",        bandwidth: "500 Mbps",  monthlyFee: 38000, contractStart: "2021-03-01", contractEnd: "2024-02-28", status: "Active",    sites: 3  },
  { id: 4,  accountNo: "CGH-004", company: "University of Ghana",     contactName: "Prof. Ama Sarpong", phone: "0302-500381", email: "ict@ug.edu.gh",                   region: "Greater Accra", address: "Commonwealth Hall, Legon, Accra",          type: "Education",   serviceType: "Fiber",       bandwidth: "2 Gbps",    monthlyFee: 55000, contractStart: "2020-09-01", contractEnd: "2025-08-31", status: "Active",    sites: 12 },
  { id: 5,  accountNo: "CGH-005", company: "Kumasi City Mall",        contactName: "Eric Osei",         phone: "0322-200400", email: "operations@kumasicitymall.com",   region: "Ashanti",       address: "Lake Road, Kumasi",                        type: "Commercial",  serviceType: "Fiber",       bandwidth: "500 Mbps",  monthlyFee: 18000, contractStart: "2023-04-01", contractEnd: "2026-03-31", status: "Active",    sites: 2  },
  { id: 6,  accountNo: "CGH-006", company: "Volta River Authority",   contactName: "Yaw Darko",         phone: "0302-664941", email: "yaw.darko@vra.com",               region: "Greater Accra", address: "Electro Volta House, Accra",               type: "Government",  serviceType: "VSAT",        bandwidth: "100 Mbps",  monthlyFee: 22000, contractStart: "2022-01-01", contractEnd: "2024-12-31", status: "Active",    sites: 6  },
  { id: 7,  accountNo: "CGH-007", company: "Ghana Ports & Harbours",  contactName: "Maame Adu",         phone: "0312-021131", email: "m.adu@ghanaports.com",            region: "Western",       address: "Harbour Area, Takoradi",                   type: "Government",  serviceType: "Fiber",       bandwidth: "1 Gbps",    monthlyFee: 28000, contractStart: "2021-11-01", contractEnd: "2024-10-31", status: "Active",    sites: 4  },
  { id: 8,  accountNo: "CGH-008", company: "Newmont Ghana Gold",      contactName: "Prince Nkrumah",    phone: "0322-180000", email: "p.nkrumah@newmont.com",           region: "Bono Ahafo",    address: "Ahafo Mine Complex, Brong Ahafo",          type: "Mining",      serviceType: "VSAT",        bandwidth: "50 Mbps",   monthlyFee: 14500, contractStart: "2023-07-01", contractEnd: "2026-06-30", status: "Active",    sites: 3  },
  { id: 9,  accountNo: "CGH-009", company: "Ghana Revenue Authority", contactName: "Akosua Frimpong",   phone: "0302-673152", email: "a.frimpong@gra.gov.gh",           region: "Greater Accra", address: "Customs House, High Street, Accra",        type: "Government",  serviceType: "MPLS",        bandwidth: "200 Mbps",  monthlyFee: 25000, contractStart: "2022-03-01", contractEnd: "2025-02-28", status: "Active",    sites: 10 },
  { id: 10, accountNo: "CGH-010", company: "AngloGold Ashanti",       contactName: "Kwesi Boateng",     phone: "0322-490000", email: "kwesi.boateng@anglogold.com",     region: "Ashanti",       address: "Gold Fields House, Nhyiaeso, Kumasi",      type: "Mining",      serviceType: "VSAT",        bandwidth: "100 Mbps",  monthlyFee: 19500, contractStart: "2021-06-01", contractEnd: "2024-05-31", status: "Suspended", sites: 4  },
  { id: 11, accountNo: "CGH-011", company: "KNUST",                   contactName: "Dr. Isaac Asiedu",  phone: "0322-060351", email: "ict@knust.edu.gh",                region: "Ashanti",       address: "University Post Office, Kumasi",           type: "Education",   serviceType: "Fiber",       bandwidth: "1 Gbps",    monthlyFee: 32000, contractStart: "2020-01-01", contractEnd: "2024-12-31", status: "Active",    sites: 8  },
  { id: 12, accountNo: "CGH-012", company: "Total Energies Ghana",    contactName: "Nana Barimah",      phone: "0302-234000", email: "n.barimah@totalenergies.com",     region: "Greater Accra", address: "Airport West, PMB, Accra",                 type: "Enterprise",  serviceType: "Leased Line", bandwidth: "500 Mbps",  monthlyFee: 35000, contractStart: "2023-01-15", contractEnd: "2026-01-14", status: "Active",    sites: 5  },
  { id: 13, accountNo: "CGH-013", company: "Absa Bank Ghana",         contactName: "Efua Darko",        phone: "0302-782400", email: "e.darko@absa.com.gh",             region: "Greater Accra", address: "Barclays House, High Street, Accra",       type: "Enterprise",  serviceType: "MPLS",        bandwidth: "2 Gbps",    monthlyFee: 68000, contractStart: "2019-01-01", contractEnd: "2024-12-31", status: "Active",    sites: 15 },
  { id: 14, accountNo: "CGH-014", company: "West Hills Mall",         contactName: "Yaa Asantewaa",     phone: "0302-960100", email: "ops@westhillsmall.com",           region: "Greater Accra", address: "Weija, Greater Accra",                     type: "Commercial",  serviceType: "Fiber",       bandwidth: "200 Mbps",  monthlyFee: 11000, contractStart: "2023-09-01", contractEnd: "2026-08-31", status: "Pending",   sites: 1  },
  { id: 15, accountNo: "CGH-015", company: "Bui Power Authority",     contactName: "Mariam Abdulai",    phone: "0372-331100", email: "m.abdulai@buipower.com",          region: "Northern",      address: "Bui Generating Station, Bole",             type: "Government",  serviceType: "VSAT",        bandwidth: "150 Mbps", monthlyFee: 21000, contractStart: "2023-11-01", contractEnd: "2026-10-31", status: "Active",    sites: 2  },
  { id: 16, accountNo: "CGH-016", company: "Interplast Ghana Ltd",   contactName: "Kojo Larbi",        phone: "0312-150500", email: "infotech@interplast.com.gh",      region: "Western",       address: "Sekondi Industrial Area, Sekondi",         type: "Commercial",  serviceType: "Leased Line", bandwidth: "500 Mbps", monthlyFee: 26000, contractStart: "2024-02-01", contractEnd: "2027-01-31", status: "Active",    sites: 3  },
  { id: 17, accountNo: "CGH-017", company: "Sunyani Municipal Assembly", contactName: "Adwoa Boateng", phone: "0352-720100", email: "it@sunyanimunicipal.gov.gh", region: "Bono", address: "Municipal Assembly Premises, Sunyani",    type: "Government",  serviceType: "Fiber",       bandwidth: "300 Mbps", monthlyFee: 17000, contractStart: "2024-04-15", contractEnd: "2027-04-14", status: "Active",    sites: 2  },
];

const SERVICES = [
  { id: "INT-01", name: "Internet",     type: "Internet",     bandwidth: "100 Mbps", uplink: "50 Mbps",   downlink: "100 Mbps", sla: "99.5%",  monthlyFee: 8500,  setupFee: 5000,  contractMin: 12, clients: 1 },
  { id: "WAN-01", name: "WAN",          type: "WAN",          bandwidth: "500 Mbps", uplink: "250 Mbps",  downlink: "500 Mbps", sla: "99.7%",  monthlyFee: 18000, setupFee: 8000,  contractMin: 12, clients: 2 },
  { id: "LL-01",  name: "Leased Line",  type: "Leased Line",  bandwidth: "1 Gbps",   uplink: "1 Gbps",    downlink: "1 Gbps",   sla: "99.9%",  monthlyFee: 32000, setupFee: 15000, contractMin: 24, clients: 3 },
  { id: "WH-01",  name: "Web Hosting",  type: "Web Hosting",  bandwidth: "2 Gbps",   uplink: "2 Gbps",    downlink: "2 Gbps",   sla: "99.99%", monthlyFee: 55000, setupFee: 25000, contractMin: 36, clients: 1 },
];

const BRANCHES = [
  { id: 1, name: "Accra HQ",        location: "Airport City, Accra",          region: "Greater Accra", manager: "Kwabena Koomson",   phone: "0302-812000", email: "accra@comsysghana.com",    staff: 45, clients: 9, established: "2008-03-01" },
  { id: 2, name: "Kumasi Branch",   location: "Adum, Kumasi",                 region: "Ashanti",       manager: "Adwoa Mensah",       phone: "0322-241500", email: "kumasi@comsysghana.com",   staff: 18, clients: 3, established: "2012-06-01" },
  { id: 3, name: "Takoradi Branch", location: "Harbour Road, Takoradi",       region: "Western",       manager: "Kofi Adjei",         phone: "0312-023100", email: "takoradi@comsysghana.com", staff: 12, clients: 1, established: "2015-01-01" },
  { id: 4, name: "Tamale Branch",   location: "Central Market Area, Tamale",  region: "Northern",      manager: "Abdul-Razak Ibrahim", phone: "0372-022500", email: "tamale@comsysghana.com",   staff: 8,  clients: 1, established: "2019-09-01" },
];

const SITES = [
  { id: 1,  siteCode: "AC-01", clientId: 1,  client: "Ghana Commercial Bank",   siteName: "Accra",                 address: "Thorpe Road, Accra",              sitePhysicalLocation: "Thorpe Road, Accra", siteGpsLocation: "5.5563, -0.1965", region: "Greater Accra", type: "Primary",   equipment: "Cisco ASR 1001",      installDate: "2023-01-15", uptime: "99.97", status: "Online",   bandwidth: "1 Gbps"    },
  { id: 2,  siteCode: "KU-01", clientId: 1,  client: "Ghana Commercial Bank",   siteName: "Kumasi",                address: "Prempeh II St, Kumasi",           sitePhysicalLocation: "Prempeh II St, Kumasi", siteGpsLocation: "6.6885, -1.6244", region: "Ashanti",       type: "Secondary", equipment: "Cisco ISR 4331",       installDate: "2023-02-01", uptime: "99.82", status: "Online",   bandwidth: "100 Mbps"  },
  { id: 3,  siteCode: "LE-01", clientId: 4,  client: "University of Ghana",     siteName: "Legon",                 address: "Legon Campus, Accra",             sitePhysicalLocation: "Legon Campus, Accra", siteGpsLocation: "5.6500, -0.1943", region: "Greater Accra", type: "Primary",   equipment: "Juniper MX204",       installDate: "2020-09-15", uptime: "99.91", status: "Online",   bandwidth: "2 Gbps"    },
  { id: 4,  siteCode: "KB-01", clientId: 4,  client: "University of Ghana",     siteName: "Korle-Bu",              address: "Korle-Bu, Accra",                 sitePhysicalLocation: "Korle-Bu, Accra", siteGpsLocation: "5.5457, -0.2140", region: "Greater Accra", type: "Secondary", equipment: "Cisco ASR 900",        installDate: "2021-01-10", uptime: "99.78", status: "Online",   bandwidth: "500 Mbps"  },
  { id: 5,  siteCode: "AK-01", clientId: 6,  client: "Volta River Authority",   siteName: "Akosombo",              address: "Akosombo Dam, Eastern",           sitePhysicalLocation: "Akosombo Dam, Eastern", siteGpsLocation: "6.3048, 0.0529", region: "Eastern",       type: "Primary",   equipment: "iDirect 950mp",       installDate: "2022-03-20", uptime: "98.50", status: "Online",   bandwidth: "100 Mbps"  },
  { id: 6,  siteCode: "KP-01", clientId: 6,  client: "Volta River Authority",   siteName: "Kpong",                 address: "Kpong Power Station, Eastern",    sitePhysicalLocation: "Kpong Power Station, Eastern", siteGpsLocation: "6.3201, 0.0935", region: "Eastern",       type: "Secondary", equipment: "VSAT Terminal SD",     installDate: "2022-04-05", uptime: "97.20", status: "Degraded", bandwidth: "20 Mbps"   },
  { id: 7,  siteCode: "AH-01", clientId: 8,  client: "Newmont Ghana Gold",      siteName: "Ahafo",                 address: "Ahafo Mine Complex, Brong Ahafo", sitePhysicalLocation: "Ahafo Mine Complex, Brong Ahafo", siteGpsLocation: "7.0515, -2.6247", region: "Bono Ahafo",    type: "Primary",   equipment: "iDirect 950mp",       installDate: "2023-07-15", uptime: "99.20", status: "Online",   bandwidth: "50 Mbps"   },
  { id: 8,  siteCode: "AS-01", clientId: 9,  client: "Ghana Revenue Authority", siteName: "Accra South",           address: "Customs House, Accra",            sitePhysicalLocation: "Customs House, Accra", siteGpsLocation: "5.5543, -0.2030", region: "Greater Accra", type: "Primary",   equipment: "Cisco Catalyst 9500", installDate: "2022-03-15", uptime: "99.92", status: "Online",   bandwidth: "200 Mbps"  },
  { id: 9,  siteCode: "TM-01", clientId: 9,  client: "Ghana Revenue Authority", siteName: "Tema",                  address: "Tema Port, Greater Accra",        sitePhysicalLocation: "Tema Port, Greater Accra", siteGpsLocation: "5.6587, -0.0164", region: "Greater Accra", type: "Secondary", equipment: "Cisco Catalyst 9300", installDate: "2022-04-01", uptime: "99.85", status: "Online",   bandwidth: "100 Mbps"  },
  { id: 10, siteCode: "OB-01", clientId: 10, client: "AngloGold Ashanti",       siteName: "Obuasi",               address: "Obuasi Mine, Ashanti",            sitePhysicalLocation: "Obuasi Mine, Ashanti", siteGpsLocation: "6.1889, -1.6966", region: "Ashanti",       type: "Primary",   equipment: "VSAT Enterprise",     installDate: "2021-06-10", uptime: "0.00",  status: "Offline",  bandwidth: "100 Mbps"  },
  { id: 11, siteCode: "CB-01", clientId: 13, client: "Absa Bank Ghana",         siteName: "Accra CBD",             address: "High Street, Accra",              sitePhysicalLocation: "High Street, Accra", siteGpsLocation: "5.5529, -0.1980", region: "Greater Accra", type: "Primary",   equipment: "Juniper MX480",       installDate: "2019-02-01", uptime: "99.98", status: "Online",   bandwidth: "2 Gbps"    },
  { id: 12, siteCode: "KE-01", clientId: 11, client: "KNUST",                   siteName: "Kumasi East",           address: "University Ave, Kumasi",          sitePhysicalLocation: "University Ave, Kumasi", siteGpsLocation: "6.6752, -1.5635", region: "Ashanti",       type: "Primary",   equipment: "Cisco Nexus 9508",    installDate: "2020-01-20", uptime: "99.85", status: "Online",   bandwidth: "1 Gbps"    },
  { id: 13, siteCode: "TH-01", clientId: 7,  client: "Ghana Ports & Harbours",  siteName: "Tema Harbour",         address: "Tema Port, Greater Accra",        sitePhysicalLocation: "Tema Port, Greater Accra", siteGpsLocation: "5.6300, -0.0147", region: "Greater Accra", type: "Primary",   equipment: "Cisco ASR 9001",      installDate: "2022-01-01", uptime: "99.95", status: "Online",   bandwidth: "1 Gbps"    },
  { id: 14, siteCode: "KN-01", clientId: 5,  client: "Kumasi City Mall",        siteName: "Kumasi North",          address: "Lake Road, Kumasi",               sitePhysicalLocation: "Lake Road, Kumasi", siteGpsLocation: "6.6942, -1.6167", region: "Ashanti",       type: "Primary",   equipment: "Ubiquiti EdgeRouter", installDate: "2023-04-15", uptime: "99.60", status: "Online",   bandwidth: "500 Mbps"  },
  { id: 15, siteCode: "BO-01", clientId: 15, client: "Bui Power Authority",     siteName: "Bole",                  address: "Bui Generating Station, Bole",     sitePhysicalLocation: "Bui Generating Station, Bole", siteGpsLocation: "8.0940, -2.8840", region: "Northern",      type: "Primary",   equipment: "iDirect 950mp",       installDate: "2023-11-18", uptime: "99.40", status: "Online",   bandwidth: "150 Mbps"  },
  { id: 16, siteCode: "SK-01", clientId: 16, client: "Interplast Ghana Ltd",   siteName: "Sekondi",               address: "Sekondi Industrial Area",        sitePhysicalLocation: "Sekondi Industrial Area", siteGpsLocation: "4.9354, -1.7186", region: "Western",       type: "Secondary", equipment: "Cisco ISR 4431",       installDate: "2024-02-10", uptime: "99.74", status: "Online",   bandwidth: "500 Mbps"  },
  { id: 17, siteCode: "SU-01", clientId: 17, client: "Sunyani Municipal Assembly", siteName: "Sunyani",           address: "Municipal Assembly Premises, Sunyani", sitePhysicalLocation: "Municipal Assembly Premises, Sunyani", siteGpsLocation: "7.3392, -2.3120", region: "Bono",          type: "Primary",   equipment: "Juniper SRX300",      installDate: "2024-04-20", uptime: "99.66", status: "Online",   bandwidth: "300 Mbps"  },
];

function initials(name: string): string {
  return name.split(/\s+/).filter(Boolean).map(w => w[0]).slice(0, 2).join("").toUpperCase();
}

function avatarBg(name: string): string {
  const palette = [BRAND.maroon, BRAND.blue, BRAND.cyan, BRAND.teal, BRAND.gold, "#4CC9F0", "#6D7C8F", "#3D7B87"];
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) & 0xffff;
  return palette[h % palette.length];
}

function CompanyAvatar({ name, size = 36 }: { name: string; size?: number }) {
  const color = avatarBg(name);
  return (
    <div
      style={{ width: size, height: size, backgroundColor: `${color}18`, border: `1px solid ${color}35`, borderRadius: 3, flexShrink: 0 }}
      className="flex items-center justify-center"
      title={name}
    >
      <span style={{ fontSize: size * 0.32, color, fontFamily: "'DM Mono', monospace", fontWeight: 600 }}>
        {initials(name)}
      </span>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const cls: Record<string, string> = {
    Active:           "bg-teal-500/10 text-teal-400 border-teal-500/20",
    Online:           "bg-teal-500/10 text-teal-400 border-teal-500/20",
    Pending:          "bg-violet-500/10 text-violet-400 border-violet-500/20",
    Suspended:        "bg-amber-500/10 text-amber-400 border-amber-500/20",
    Degraded:         "bg-amber-500/10 text-amber-400 border-amber-500/20",
    Terminated:       "bg-red-500/10 text-red-400 border-red-500/20",
    Offline:          "bg-red-500/10 text-red-400 border-red-500/20",
    Fiber:            "bg-teal-500/10 text-teal-400 border-teal-500/20",
    Internet:         "bg-teal-500/10 text-teal-400 border-teal-500/20",
    WAN:              "bg-cyan-500/10 text-cyan-400 border-cyan-500/20",
    MPLS:             "bg-amber-500/10 text-amber-400 border-amber-500/20",
    VSAT:             "bg-indigo-500/10 text-indigo-400 border-indigo-500/20",
    "Leased Line":    "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
    "Web Hosting":    "bg-pink-500/10 text-pink-400 border-pink-500/20",
    Radio:            "bg-cyan-500/10 text-cyan-400 border-cyan-500/20",
    "4G LTE":         "bg-pink-500/10 text-pink-400 border-pink-500/20",
    Enterprise:       "bg-blue-500/10 text-blue-400 border-blue-500/20",
    Government:       "bg-violet-500/10 text-violet-400 border-violet-500/20",
    Education:        "bg-sky-500/10 text-sky-400 border-sky-500/20",
    Mining:           "bg-orange-500/10 text-orange-400 border-orange-500/20",
    Commercial:       "bg-rose-500/10 text-rose-400 border-rose-500/20",
  };
  const base = cls[status] ?? "bg-slate-500/10 text-slate-400 border-slate-500/20";
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded border text-[10px] font-mono font-medium tracking-wide ${base}`}>
      {status}
    </span>
  );
}

function StatCard({ label, value, sub, icon: Icon, trend, trendUp, accent, onClick }: {
  label: string; value: string; sub?: string; icon: React.ElementType;
  trend?: string; trendUp?: boolean; accent?: string; onClick?: () => void;
}) {
  const color = accent ?? BRAND.blue;
  return (
    <button
      type="button"
      onClick={onClick}
      className="w-full bg-card border border-border rounded p-5 flex flex-col gap-3 hover:border-primary/15 transition-colors text-left"
    >
      <div className="flex items-start justify-between">
        <div className="flex-1 min-w-0">
          <p className="text-[10px] font-mono text-muted-foreground uppercase tracking-widest">{label}</p>
          <p className="text-2xl font-semibold text-foreground mt-1.5 font-mono">{value}</p>
          {sub && <p className="text-[11px] text-muted-foreground mt-0.5">{sub}</p>}
        </div>
        <div className="w-8 h-8 rounded flex items-center justify-center flex-shrink-0 ml-3" style={{ backgroundColor: `${color}15` }}>
          <Icon className="w-4 h-4" style={{ color }} />
        </div>
      </div>
      {trend && (
        <div className="flex items-center gap-1.5 pt-2 border-t border-border">
          {trendUp
            ? <TrendingUp className="w-3 h-3 text-teal-400" />
            : <TrendingDown className="w-3 h-3 text-red-400" />}
          <span className={`text-[10px] font-mono ${trendUp ? "text-teal-400" : "text-red-400"}`}>{trend}</span>
        </div>
      )}
    </button>
  );
}

function SectionHeader({ title, sub }: { title: string; sub?: string }) {
  return (
    <div className="mb-6">
      <h2 className="text-sm font-semibold text-foreground tracking-tight">{title}</h2>
      {sub && <p className="text-[11px] font-mono text-muted-foreground mt-0.5">{sub}</p>}
    </div>
  );
}

function formatMonthYear(date: Date) {
  return new Intl.DateTimeFormat("en-US", {
    month: "long",
    year: "numeric",
  }).format(date);
}

function formatShortDate(date: Date) {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(date);
}

// Dashboard overview with KPI summaries and quick-jump shortcuts.
function Dashboard({ clients, onNavigate, sites = SITES, services = SERVICES, currentDate = new Date() }: { clients: ClientRow[]; onNavigate?: (tab: string) => void; sites?: typeof SITES; services?: typeof SERVICES; currentDate?: Date }) {
  const activeClients = clients.filter(c => c.status === "Active").length;
  const onlineSites   = sites.filter(s => s.status === "Online").length;
  const degradedSites = sites.filter(s => s.status === "Degraded").length;
  const offlineSites  = sites.filter(s => s.status === "Offline").length;
  const serviceHighlights = services.slice(0, 3);
  const siteAlerts = sites.filter(s => s.status !== "Online").slice(0, 3);

  const quickLinks = [
    { id: "clients", label: "Customers", value: `${clients.length} accounts`, icon: Users, accent: BRAND.blue },
    { id: "services", label: "Services", value: `${services.length} offerings`, icon: Wifi, accent: BRAND.teal },
    { id: "sites", label: "Sites", value: `${sites.length} installations`, icon: MapPin, accent: BRAND.cyan },
  ];

  return (
    <div className="space-y-8">
      <SectionHeader title="Network Overview" sub={`Comsys Ghana Limited · ${formatMonthYear(currentDate)}`} />

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
        <StatCard
          label="Active Clients"
          value={String(activeClients)}
          sub={`${clients.length} total accounts`}
          icon={Users}
          trend="+2 this quarter"
          trendUp
          onClick={() => onNavigate?.("clients")}
        />
        <StatCard
          label="Service Types"
          value={String(services.length)}
          sub="active offerings"
          icon={Wifi}
          accent={BRAND.teal}
          onClick={() => onNavigate?.("services")}
        />
        <StatCard
          label="Regional Sites"
          value={String(new Set(sites.map(site => site.region)).size)}
          sub="locations covered"
          icon={MapPin}
          accent="#6366F1"
          onClick={() => onNavigate?.("sites")}
        />
      </div>

      <div className="grid grid-cols-1 gap-4">
        <div className="space-y-3">
          <p className="text-[10px] font-mono text-muted-foreground uppercase tracking-widest">Operational Snapshot</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
            <button
              type="button"
              onClick={() => onNavigate?.("clients")}
              className="bg-card border border-border rounded p-4 text-left hover:border-primary/20 hover:bg-secondary/15 transition-colors"
            >
              <p className="text-[10px] font-mono uppercase tracking-widest text-muted-foreground">Top Customer</p>
              <p className="mt-3 text-sm font-semibold text-foreground">{clients[0]?.company ?? "No customers"}</p>
              <p className="mt-1 text-[11px] font-mono text-primary">{clients[0]?.accountNo ?? "—"}</p>
              <p className="mt-3 text-[10px] font-mono text-muted-foreground">{clients[0]?.status ?? "No status"}</p>
            </button>

            <button
              type="button"
              onClick={() => onNavigate?.("sites")}
              className="bg-card border border-border rounded p-4 text-left hover:border-primary/20 hover:bg-secondary/15 transition-colors"
            >
              <p className="text-[10px] font-mono uppercase tracking-widest text-muted-foreground">Site Health</p>
              <p className="mt-3 text-sm font-semibold text-foreground">{onlineSites} online</p>
              <p className="mt-1 text-[11px] font-mono text-amber-400">{degradedSites} degraded</p>
              <p className="mt-3 text-[10px] font-mono text-muted-foreground">{offlineSites} offline</p>
            </button>

            <button
              type="button"
              onClick={() => onNavigate?.("services")}
              className="bg-card border border-border rounded p-4 text-left hover:border-primary/20 hover:bg-secondary/15 transition-colors"
            >
              <p className="text-[10px] font-mono uppercase tracking-widest text-muted-foreground">Service Mix</p>
              <div className="mt-3 space-y-2">
                {serviceHighlights.map(service => (
                  <div key={service.id} className="flex items-center justify-between">
                    <span className="text-[10px] font-mono text-muted-foreground">{service.name}</span>
                    <StatusBadge status={service.type} />
                  </div>
                ))}
              </div>
            </button>
          </div>
        </div>

      </div>

      <div className="space-y-3">
        <p className="text-[10px] font-mono text-muted-foreground uppercase tracking-widest">Quick Access</p>
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
          {quickLinks.map(item => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => onNavigate?.(item.id)}
                className="group flex items-center justify-between rounded-xl border border-border bg-card p-4 text-left shadow-sm transition-all duration-200 hover:-translate-y-0.5 hover:border-primary/30 hover:shadow-md hover:bg-secondary/15"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg border border-transparent" style={{ backgroundColor: `${item.accent}18`, borderColor: `${item.accent}25` }}>
                    <Icon className="h-4 w-4" style={{ color: item.accent }} />
                  </div>
                  <div>
                    <p className="text-[10px] font-mono uppercase tracking-widest text-muted-foreground">{item.label}</p>
                    <p className="text-sm font-semibold text-foreground mt-0.5">{item.value}</p>
                  </div>
                </div>
                <div className="flex h-7 w-7 items-center justify-center rounded-full bg-secondary/40 text-muted-foreground transition-colors group-hover:bg-primary/10 group-hover:text-primary">
                  <ChevronRight className="h-3.5 w-3.5" />
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

type ClientRow = (typeof CLIENTS)[number] & { siteId?: string };

function resolveClientSiteId(client: ClientRow, siteList = SITES): string {
  return client.siteId ?? siteList.find(site => site.clientId === client.id)?.siteCode ?? "";
}

const defaultClientDraft = {
  accountNo: "",
  siteId: "",
  company: "",
  contactName: "",
  phone: "",
  email: "",
  region: "Greater Accra",
  address: "",
  type: "Enterprise",
  serviceType: "Internet",
  bandwidth: "100 Mbps",
  monthlyFee: 0,
  contractStart: new Date().toISOString().slice(0, 10),
  contractEnd: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
  status: "Active",
  sites: 1,
};

// Client registry with search, status filters, add/edit actions, and account detail view.
function ClientsModule({ clients, setClients, sites = SITES }: { clients: ClientRow[]; setClients: React.Dispatch<React.SetStateAction<ClientRow[]>>; sites?: typeof SITES }) {
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<ClientRow | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingClientId, setEditingClientId] = useState<number | null>(null);
  const [draft, setDraft] = useState(defaultClientDraft);
  const [columnFilterOpen, setColumnFilterOpen] = useState(false);
  const [visibleColumns, setVisibleColumns] = useState<Record<string, boolean>>({
    customerId: true,
    customerName: true,
    customerTPOCName: true,
  });

  const customerColumns = [
    { key: "customerId", label: "Customer ID" },
    { key: "customerName", label: "Customer Name" },
    { key: "customerTPOCName", label: "Customer TPOC" },
  ];

  const visibleColumnList = customerColumns.filter(column => visibleColumns[column.key]);

  const filtered = useMemo(() =>
    clients.filter(c => {
      const siteId = resolveClientSiteId(c, sites);

      return c.accountNo.toLowerCase().includes(search.toLowerCase()) ||
        siteId.toLowerCase().includes(search.toLowerCase()) ||
        c.contactName.toLowerCase().includes(search.toLowerCase()) ||
        c.email.toLowerCase().includes(search.toLowerCase()) ||
        c.phone.toLowerCase().includes(search.toLowerCase()) ||
        c.company.toLowerCase().includes(search.toLowerCase());
    }), [clients, sites, search]);

  function clientToDraft(client: ClientRow) {
    return {
      accountNo: client.accountNo,
      siteId: resolveClientSiteId(client, sites),
      company: client.company,
      contactName: client.contactName,
      phone: client.phone,
      email: client.email,
      region: client.region,
      address: client.address,
      type: client.type,
      serviceType: client.serviceType,
      bandwidth: client.bandwidth,
      monthlyFee: client.monthlyFee,
      contractStart: client.contractStart,
      contractEnd: client.contractEnd,
      status: client.status,
      sites: client.sites,
    };
  }

  function openAddForm() {
    setEditingClientId(null);
    setDraft(defaultClientDraft);
    setShowAddForm(true);
  }

  function openEditForm(client: ClientRow) {
    setEditingClientId(client.id);
    setDraft(clientToDraft(client));
    setShowAddForm(true);
  }

  function handleDraftChange<K extends keyof typeof defaultClientDraft>(field: K, value: (typeof defaultClientDraft)[K]) {
    setDraft(prev => ({ ...prev, [field]: value }));
  }

  function handleSaveClient(event: React.FormEvent) {
    event.preventDefault();

    if (!draft.company.trim() || !draft.contactName.trim()) return;

    const payload: ClientRow = {
      id: editingClientId ?? Date.now(),
      accountNo: draft.accountNo.trim() || `CGH-${String(clients.length + 1).padStart(3, "0")}`,
      siteId: draft.siteId.trim(),
      company: draft.company.trim(),
      contactName: draft.contactName.trim(),
      phone: draft.phone.trim(),
      email: draft.email.trim(),
      region: draft.region,
      address: draft.address.trim() || "",
      type: draft.type,
      serviceType: draft.serviceType,
      bandwidth: draft.bandwidth,
      monthlyFee: Number(draft.monthlyFee) || 0,
      contractStart: draft.contractStart,
      contractEnd: draft.contractEnd,
      status: draft.status,
      sites: Number(draft.sites) || 1,
    };

    if (editingClientId !== null) {
      setClients(prev => prev.map(client => client.id === editingClientId ? payload : client));
      setSelected(payload);
    } else {
      setClients(prev => [payload, ...prev]);
      setSelected(payload);
    }

    setShowAddForm(false);
    setEditingClientId(null);
    setDraft(defaultClientDraft);
  }

  if (selected) {
    const clientSites = sites.filter(s => s.clientId === selected.id);
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between gap-3">
          <button
            onClick={() => setSelected(null)}
            className="flex items-center gap-1.5 text-[11px] font-mono text-muted-foreground hover:text-foreground transition-colors"
          >
            <ChevronRight className="w-3.5 h-3.5 rotate-180" />
            All Clients
          </button>

          <button
            type="button"
            onClick={() => openEditForm(selected)}
            className="rounded bg-primary px-3 py-2 text-[10px] font-mono font-semibold uppercase tracking-wider text-primary-foreground transition-colors hover:opacity-90"
          >
            Edit Client
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div className="bg-card border border-border rounded p-5 flex flex-col gap-4">
            <div className="flex items-start gap-3">
              <CompanyAvatar name={selected.company} size={44} />
              <div className="flex-1 min-w-0">
                <h3 className="text-sm font-semibold text-foreground leading-snug">{selected.company}</h3>
                <p className="text-[10px] font-mono text-muted-foreground mt-0.5">{selected.accountNo}</p>
                <div className="flex items-center gap-1.5 mt-2 flex-wrap">
                  <StatusBadge status={selected.status} />
                  <StatusBadge status={selected.type} />
                </div>
              </div>
            </div>

            <div className="border-t border-border pt-3 space-y-0">
              {([
                ["Customer ID", selected.accountNo],
                ["Site ID", clientSites[0]?.siteCode ?? "—"],
                ["Customer TPOC Name", selected.contactName],
                ["Customer TPOC Email", selected.email],
                ["Customer TPOC Phone", selected.phone],
                ["Customer Name", selected.company],
              ] as [string, string][]).map(([k, v]) => (
                <div key={k} className="flex items-center justify-between gap-4 py-2 border-b border-border last:border-0">
                  <span className="text-[10px] font-mono text-muted-foreground">{k}</span>
                  <span className="text-[11px] font-mono text-foreground text-right">{v}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="lg:col-span-2 bg-card border border-border rounded p-5">
            <p className="text-[10px] font-mono text-muted-foreground uppercase tracking-widest mb-3">Customer Reference</p>
            <div className="grid grid-cols-2 gap-4">
              {([
                ["Customer ID", selected.accountNo],
                ["Site ID", clientSites[0]?.siteCode ?? "—"],
                ["Customer TPOC Name", selected.contactName],
                ["Customer TPOC Phone", selected.phone],
                ["Customer TPOC Email", selected.email],
                ["Customer Name", selected.company],
              ] as [string, string][]).map(([k, v]) => (
                <div key={k}>
                  <p className="text-[9px] font-mono text-muted-foreground uppercase tracking-wider">{k}</p>
                  <p className={`text-xs mt-0.5 leading-relaxed ${k.includes("Email") ? "text-primary font-mono" : "text-foreground"}`}>{v}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* This table view is the main client registry. It is rendered when no client is selected. */}
      <div className="flex items-center justify-between gap-3">
        <SectionHeader title="Customer Registry" sub={`${filtered.length} of ${clients.length} customer accounts`} />
        <button
          type="button"
          onClick={() => {
            if (showAddForm) {
              setShowAddForm(false);
              setEditingClientId(null);
              setDraft(defaultClientDraft);
            } else {
              openAddForm();
            }
          }}
          className="rounded bg-primary px-3 py-2 text-[10px] font-mono font-semibold uppercase tracking-wider text-primary-foreground transition-colors hover:opacity-90"
        >
          {showAddForm ? "Close" : "Add Client"}
        </button>
      </div>

      {showAddForm && (
        <form onSubmit={handleSaveClient} className="bg-card border border-border rounded p-4 space-y-4">
          <div className="flex items-center justify-between gap-3">
            <p className="text-[10px] font-mono uppercase tracking-widest text-muted-foreground">{editingClientId !== null ? "Edit Client" : "New Client"}</p>
            <button type="button" onClick={() => { setShowAddForm(false); setEditingClientId(null); setDraft(defaultClientDraft); }} className="text-[10px] font-mono text-muted-foreground hover:text-foreground">Cancel</button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <input value={draft.accountNo} onChange={e => handleDraftChange("accountNo", e.target.value as never)} placeholder="Customer ID" className="bg-secondary/40 border border-border rounded px-3 py-2 text-xs font-mono text-foreground placeholder:text-muted-foreground outline-none focus:border-primary/30" />
            <select value={draft.siteId} onChange={e => handleDraftChange("siteId", e.target.value as never)} className="bg-secondary/40 border border-border rounded px-3 py-2 text-xs font-mono text-foreground outline-none focus:border-primary/30">
              <option value="">Select Site ID</option>
              {Array.from(new Set(sites.map(site => site.siteCode))).map(siteCode => (
                <option key={siteCode} value={siteCode}>{siteCode}</option>
              ))}
            </select>
            <input value={draft.contactName} onChange={e => handleDraftChange("contactName", e.target.value as never)} placeholder="Customer TPOC Name" required className="bg-secondary/40 border border-border rounded px-3 py-2 text-xs font-mono text-foreground placeholder:text-muted-foreground outline-none focus:border-primary/30" />
            <input value={draft.phone} onChange={e => handleDraftChange("phone", e.target.value as never)} placeholder="Customer TPOC Phone" className="bg-secondary/40 border border-border rounded px-3 py-2 text-xs font-mono text-foreground placeholder:text-muted-foreground outline-none focus:border-primary/30" />
            <input value={draft.email} onChange={e => handleDraftChange("email", e.target.value as never)} placeholder="Customer TPOC Email" className="bg-secondary/40 border border-border rounded px-3 py-2 text-xs font-mono text-foreground placeholder:text-muted-foreground outline-none focus:border-primary/30 md:col-span-2" />
            <input value={draft.company} onChange={e => handleDraftChange("company", e.target.value as never)} placeholder="Customer Name" required className="bg-secondary/40 border border-border rounded px-3 py-2 text-xs font-mono text-foreground placeholder:text-muted-foreground outline-none focus:border-primary/30 md:col-span-2" />
          </div>

          <div className="flex justify-end gap-3 pt-2">
            <button type="button" onClick={() => { setShowAddForm(false); setEditingClientId(null); setDraft(defaultClientDraft); }} className="rounded border border-border px-3 py-2 text-[10px] font-mono uppercase tracking-wider text-muted-foreground">Cancel</button>
            <button type="submit" className="rounded bg-primary px-3 py-2 text-[10px] font-mono uppercase tracking-wider text-primary-foreground">{editingClientId !== null ? "Save Changes" : "Save Client"}</button>
          </div>
        </form>
      )}

      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-52">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search customer ID, site ID, TPOC name, email, phone, customer name..."
            className="w-full bg-secondary/40 border border-border rounded pl-9 pr-3 py-2 text-xs font-mono text-foreground placeholder:text-muted-foreground outline-none focus:border-primary/30 transition-colors"
          />
        </div>

        <div className="relative">
          <button
            type="button"
            onClick={() => setColumnFilterOpen(!columnFilterOpen)}
            className="bg-secondary/40 border border-border rounded px-3 py-2 text-xs font-mono text-foreground outline-none focus:border-primary/30 cursor-pointer"
          >
            Columns ({visibleColumnList.length})
          </button>

          {columnFilterOpen && (
            <div className="absolute right-0 top-full z-20 mt-2 w-64 rounded border border-border bg-card p-2 shadow-lg">
              {customerColumns.map(column => (
                <label
                  key={column.key}
                  className="flex items-center gap-2 rounded px-2 py-1.5 text-[10px] font-mono uppercase tracking-widest text-muted-foreground hover:bg-secondary/20 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={visibleColumns[column.key]}
                    onChange={() => setVisibleColumns(prev => ({
                      ...prev,
                      [column.key]: !prev[column.key],
                    }))}
                    className="accent-primary"
                  />
                  {column.label}
                </label>
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="bg-card border border-border rounded overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-[720px] w-full border-collapse border border-border">
            <thead>
              <tr className="bg-secondary/20">
                {visibleColumnList.map(column => (
                  <th key={column.key} className="border border-border bg-secondary/20 px-4 py-3 text-left text-[9px] font-mono text-muted-foreground uppercase tracking-widest whitespace-nowrap">{column.label}</th>
                ))}
              </tr>
            </thead>
            <tbody>
            {filtered.map(c => {
              const cells = {
                customerId: <td key="customerId" className="border border-border px-4 py-3 text-[10px] font-mono text-muted-foreground">{c.accountNo}</td>,
                customerName: <td key="customerName" className="border border-border px-4 py-3 text-xs text-foreground">{c.company}</td>,
                customerTPOCName: (
                  <td key="customerTPOCName" className="border border-border px-4 py-3 text-xs text-foreground align-top">
                    <button
                      type="button"
                      onClick={event => {
                        event.stopPropagation();
                        setSelected(c);
                      }}
                      onMouseEnter={event => event.stopPropagation()}
                      onMouseLeave={event => event.stopPropagation()}
                      className="group relative inline-flex flex-col items-start text-left outline-none"
                      aria-label={`Customer TPOC details for ${c.contactName}`}
                    >
                      <span className="text-xs text-foreground">{c.contactName}</span>
                      <span className="pointer-events-none absolute left-0 top-full z-20 mt-1 w-56 rounded border border-border bg-card p-2 text-left shadow-lg opacity-0 transition-opacity duration-150 group-hover:opacity-100 group-focus:opacity-100 group-focus-visible:opacity-100">
                        <span className="block text-[9px] font-mono uppercase tracking-widest text-muted-foreground">Customer TPOC</span>
                        <span className="mt-1 block text-[11px] text-foreground">{c.contactName}</span>
                        <span className="mt-1 block text-[10px] font-mono text-primary/90">{c.email}</span>
                        <span className="mt-1 block text-[10px] font-mono text-muted-foreground">{c.phone}</span>
                      </span>
                    </button>
                  </td>
                ),
              };

              return (
                <tr
                  key={c.id}
                  onClick={() => setSelected(c)}
                  className="hover:bg-secondary/25 transition-colors cursor-pointer"
                >
                  {visibleColumnList.map(column => cells[column.key as keyof typeof cells])}
                </tr>
              );
            })}
          </tbody>
          </table>
        </div>
        {filtered.length === 0 && (
          <p className="py-12 text-center text-xs font-mono text-muted-foreground">No clients match the current filters.</p>
        )}
        {visibleColumnList.length === 0 && (
          <p className="py-8 text-center text-[10px] font-mono uppercase tracking-widest text-muted-foreground">Select at least one column to display.</p>
        )}
      </div>
    </div>
  );
}

// Service catalog grouped by connectivity type and device model.
function ServicesModule({ clients = CLIENTS, services = SERVICES }: { clients?: ClientRow[]; services?: typeof SERVICES }) {
  const [selectedServiceClients, setSelectedServiceClients] = useState<{ id: string; name: string; clients: string[] } | null>(null);

  const serviceDefinitions = [
    { id: "INT-01", name: "Internet", aliases: ["Internet", "Fiber"] },
    { id: "WAN-01", name: "WAN", aliases: ["WAN"] },
    { id: "LL-01", name: "Leased Line", aliases: ["Leased Line"] },
    { id: "WH-01", name: "Web Hosting", aliases: ["Web Hosting", "Web hosting"] },
  ];

  const serviceRows = serviceDefinitions.map(service => {
    const assignedClients = clients.filter(client => {
      const normalizedType = (client.serviceType || "").trim();
      return service.aliases.includes(normalizedType);
    }).map(client => client.company);

    return {
      ...service,
      clients: assignedClients,
    };
  });

  return (
    <div className="space-y-6">
      <SectionHeader title="Service Registry" sub={`${serviceRows.length} service entries`} />

      <div className="bg-card border border-border rounded overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-[500px] w-full border-collapse border border-border">
            <thead>
              <tr className="bg-secondary/20">
                {['Service ID', 'Service Name', 'Customers'].map(h => (
                  <th key={h} className="border border-border bg-secondary/20 px-4 py-3 text-left text-[9px] font-mono text-muted-foreground uppercase tracking-widest whitespace-nowrap">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
            {serviceRows.map(row => {
              const previewCount = 3;
              const visibleClients = row.clients.slice(0, previewCount);
              const hiddenCount = Math.max(row.clients.length - previewCount, 0);

              return (
                <tr key={row.id} className="hover:bg-secondary/25 transition-colors align-top">
                  <td className="border border-border px-4 py-3 text-[11px] font-mono text-muted-foreground">{row.id}</td>
                  <td className="border border-border px-4 py-3 text-xs text-foreground">{row.name}</td>
                  <td className="border border-border px-4 py-3 text-xs text-foreground">
                    {row.clients.length > 0 ? (
                      <div className="flex flex-wrap items-center gap-2">
                        {visibleClients.map(clientName => (
                          <span
                            key={clientName}
                            className="inline-flex items-center rounded border border-border bg-secondary/20 px-2 py-1 text-[10px] font-mono text-foreground"
                          >
                            {clientName}
                          </span>
                        ))}
                        {hiddenCount > 0 && (
                          <button
                            type="button"
                            className="text-[10px] font-mono uppercase tracking-widest text-blue-600 hover:text-blue-500 transition-colors"
                            onClick={() => setSelectedServiceClients({ id: row.id, name: row.name, clients: row.clients })}
                          >
                            More ({hiddenCount})
                          </button>
                        )}
                      </div>
                    ) : (
                      <span className="text-muted-foreground">No clients assigned</span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
          </table>
        </div>
      </div>

      {selectedServiceClients && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded border border-border bg-card shadow-lg">
            <div className="flex items-center justify-between border-b border-border px-4 py-3">
              <h3 className="text-sm font-semibold text-foreground">{selectedServiceClients.name}</h3>
              <button
                type="button"
                onClick={() => setSelectedServiceClients(null)}
                className="text-muted-foreground hover:text-foreground"
                aria-label="Close"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="p-4">
              <p className="mb-3 text-[10px] font-mono uppercase tracking-widest text-muted-foreground">Clients</p>
              <div className="space-y-2">
                {selectedServiceClients.clients.map(clientName => (
                  <div key={clientName} className="rounded border border-border bg-secondary/20 px-3 py-2 text-xs text-foreground">
                    {clientName}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function SitesModule({ sites = SITES }: { sites?: typeof SITES }) {
  const [search, setSearch] = useState("");

  const filtered = useMemo(() =>
    sites.filter(s =>
      s.siteCode.toLowerCase().includes(search.toLowerCase()) ||
      s.siteName.toLowerCase().includes(search.toLowerCase()) ||
      s.sitePhysicalLocation.toLowerCase().includes(search.toLowerCase()) ||
      s.siteGpsLocation.toLowerCase().includes(search.toLowerCase())
    ), [sites, search]);

  const online   = sites.filter(s => s.status === "Online").length;
  const degraded = sites.filter(s => s.status === "Degraded").length;
  const offline  = sites.filter(s => s.status === "Offline").length;

  return (
    <div className="space-y-6">
      <SectionHeader title="Customer Sites" sub={`${sites.length} total sites · ${online} online · ${degraded} degraded · ${offline} offline`} />

      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-48">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search site ID, site name, physical location, GPS..."
            className="w-full bg-secondary/40 border border-border rounded pl-9 pr-3 py-2 text-xs font-mono text-foreground placeholder:text-muted-foreground outline-none focus:border-primary/30 transition-colors"
          />
        </div>
      </div>

      <div className="bg-card border border-border rounded overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-[760px] w-full border-collapse border border-border">
            <thead>
              <tr className="bg-secondary/20">
                {["Site ID", "Site Name", "Site Physical Location", "Site GPS Location"].map(h => (
                  <th key={h} className="border border-border bg-secondary/20 px-4 py-3 text-left text-[9px] font-mono text-muted-foreground uppercase tracking-widest whitespace-nowrap">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
            {filtered.map(site => (
              <tr key={site.id} className="hover:bg-secondary/25 transition-colors">
                <td className="border border-border px-4 py-3 text-[10px] font-mono text-muted-foreground">{site.siteCode}</td>
                <td className="border border-border px-4 py-3 text-xs text-foreground">{site.siteName}</td>
                <td className="border border-border px-4 py-3 text-[11px] font-mono text-muted-foreground whitespace-nowrap">{site.sitePhysicalLocation}</td>
                <td className="border border-border px-4 py-3 text-[11px] font-mono text-muted-foreground whitespace-nowrap">{site.siteGpsLocation}</td>
              </tr>
            ))}
          </tbody>
          </table>
        </div>
        {filtered.length === 0 && (
          <p className="py-12 text-center text-xs font-mono text-muted-foreground">No sites match the current filters.</p>
        )}
      </div>
    </div>
  );
}

const NAV = [
  { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
  { id: "clients",   label: "Customers",   icon: Users           },
  { id: "services",  label: "Services",  icon: Wifi            },
  { id: "sites",     label: "Customer Sites",     icon: MapPin          },
];

export default function App() {
  const [active, setActive]         = useState("dashboard");
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [theme, setTheme] = useState<"light" | "dark">("light");
  const [clients, setClients] = useState<ClientRow[]>(CLIENTS);
  const [sites, setSites] = useState(SITES);
  const [services, setServices] = useState(SERVICES);
  const [currentDate, setCurrentDate] = useState(new Date());

  useEffect(() => {
    const timer = window.setInterval(() => setCurrentDate(new Date()), 60_000);
    return () => window.clearInterval(timer);
  }, []);

  function navigate(id: string) {
    setActive(id);
    if (window.innerWidth < 1024) setSidebarOpen(false);
  }

  const modules: Record<string, React.ComponentType<any>> = {
    dashboard: Dashboard,
    clients:   ClientsModule,
    services:  ServicesModule,
    sites:     SitesModule,
  };
  const Current = modules[active] ?? Dashboard;

  return (
    <div
      className={`flex h-screen overflow-hidden transition-colors duration-300 ease-in-out ${theme === "dark" ? "dark bg-background" : "bg-background"}`}
      style={{ fontFamily: "'Outfit', sans-serif" }}
    >
      {sidebarOpen && (
        <button
          type="button"
          aria-label="Close navigation"
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 z-30 bg-black/30 lg:hidden"
        />
      )}

      {/* Sidebar */}
      <aside
        className={`z-40 flex-shrink-0 flex flex-col border-r border-border transition-all duration-300 ease-in-out bg-card overflow-hidden
          fixed inset-y-0 left-0 w-52
          ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}
          lg:static lg:translate-x-0 lg:w-auto
          ${sidebarOpen ? "lg:w-52" : "lg:w-12"}
          ${sidebarOpen ? "lg:translate-x-0" : "lg:translate-x-0"}
        `}
      >
        {/* Brand */}
        <div className="flex items-center gap-2.5 px-3.5 py-4 border-b border-border">
          <img src={logoUrl} alt="Comsys Ghana logo" className="h-8 w-auto object-contain flex-shrink-0" />
          {sidebarOpen && (
            <div className="overflow-hidden">
              <p className="text-xs font-semibold text-foreground whitespace-nowrap">Comsys Ghana</p>
              <p className="text-[9px] font-mono text-muted-foreground whitespace-nowrap">Client Management</p>
            </div>
          )}
        </div>

        {/* Nav items */}
        <nav className="flex-1 py-3 px-2 space-y-0.5 overflow-y-auto overflow-x-hidden">
          {NAV.map(item => {
            const Icon = item.icon;
            const isActive = active === item.id;
            return (
              <button
                key={item.id}
                onClick={() => navigate(item.id)}
                className={`w-full flex items-center gap-2.5 px-2.5 py-2 rounded text-xs transition-colors ${
                  isActive
                    ? "bg-primary/10 text-primary border border-primary/15"
                    : "text-muted-foreground hover:text-foreground hover:bg-secondary/60 border border-transparent"
                }`}
              >
                <Icon className="w-3.5 h-3.5 flex-shrink-0" />
                {sidebarOpen && <span className="font-medium whitespace-nowrap">{item.label}</span>}
                {isActive && sidebarOpen && <div className="ml-auto w-1 h-3 rounded-full bg-primary/50" />}
              </button>
            );
          })}
        </nav>

        <div className="border-t border-border p-2">
          <button
            type="button"
            onClick={() => setTheme(theme === "light" ? "dark" : "light")}
            className="w-full flex items-center justify-between gap-2 rounded border border-border bg-secondary/40 px-2.5 py-2 text-[10px] font-mono uppercase tracking-wider text-muted-foreground transition-all duration-300 ease-in-out hover:text-foreground hover:bg-secondary/70"
          >
            {sidebarOpen ? (
              <>
                <span>{theme === "light" ? "Dark mode" : "Light mode"}</span>
                {theme === "light" ? <MoonStar className="w-3.5 h-3.5 transition-transform duration-300 ease-in-out" /> : <SunMedium className="w-3.5 h-3.5 transition-transform duration-300 ease-in-out" />}
              </>
            ) : (
              <div className="mx-auto flex items-center justify-center">
                {theme === "light" ? <MoonStar className="w-3.5 h-3.5 transition-transform duration-300 ease-in-out" /> : <SunMedium className="w-3.5 h-3.5 transition-transform duration-300 ease-in-out" />}
              </div>
            )}
          </button>
        </div>
      </aside>

      {/* Main */}
      <div className={`relative flex min-w-0 flex-1 flex-col transition-all duration-300 ${sidebarOpen ? "lg:ml-0" : "lg:ml-0"}`}>
        {/* Topbar */}
        <header className="flex items-center gap-3 px-3 py-3 border-b border-border flex-shrink-0 bg-background sm:px-5">
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="w-8 h-8 flex items-center justify-center rounded text-muted-foreground hover:text-foreground transition-colors lg:w-6 lg:h-6"
          >
            {sidebarOpen ? <X className="w-3.5 h-3.5" /> : <Menu className="w-3.5 h-3.5" />}
          </button>

          <div className="flex min-w-0 items-center gap-1 text-[10px] font-mono text-muted-foreground">
            <span className="text-primary/70">CGH</span>
            <ChevronRight className="w-3 h-3" />
            <span className="truncate text-foreground capitalize">{active}</span>
          </div>

          <div className="ml-auto flex items-center gap-3 sm:gap-4">
            <div className="hidden sm:flex items-center gap-1.5">
              <div className="w-1.5 h-1.5 rounded-full bg-teal-400 animate-pulse" />
              <span className="text-[10px] font-mono text-teal-400">Network Operational</span>
            </div>
            <span className="text-[10px] font-mono text-muted-foreground hidden md:block">{formatShortDate(currentDate)}</span>
            <div className="relative">
              <Bell className="w-3.5 h-3.5 text-muted-foreground" />
              <span className="absolute -top-1.5 -right-1.5 w-3.5 h-3.5 rounded-full bg-primary text-[7px] font-mono flex items-center justify-center leading-none" style={{ color: "#070E1B" }}>3</span>
            </div>
          </div>
        </header>

        {/* Content */}
        <main
          className="flex-1 overflow-y-auto p-4 sm:p-6"
          style={{ scrollbarWidth: "none", msOverflowStyle: "none" } as React.CSSProperties}
        >
          <Current
            clients={clients}
            setClients={setClients}
            sites={sites}
            setSites={setSites}
            services={services}
            setServices={setServices}
            onNavigate={navigate}
            currentDate={currentDate}
          />
        </main>
      </div>
    </div>
  );
}
