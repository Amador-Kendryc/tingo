import React, { useState, useEffect } from 'react';
import { 
  Activity, 
  Users, 
  DollarSign, 
  MapPin, 
  FileCheck, 
  Settings, 
  Car, 
  CheckCircle, 
  XCircle, 
  ShieldAlert, 
  Search,
  Navigation,
  CreditCard,
  TrendingUp
} from 'lucide-react';

// Datos Mock para demostración interactiva
const INITIAL_DRIVERS = [
  {
    id: 'drv-1',
    name: 'Carlos Mendoza',
    phone: '+52 55 1234 5678',
    vehicle: 'Nissan Versa 2022 (Negro)',
    plate: 'ABC-1234',
    rating: 4.9,
    status: 'APPROVED',
    online: true,
    lat: 19.4326,
    lng: -99.1332,
    docs: {
      license: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400',
      registration: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      soat: 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=400'
    }
  },
  {
    id: 'drv-2',
    name: 'Roberto Gómez',
    phone: '+52 55 9876 5432',
    vehicle: 'Chevrolet Aveo 2021 (Gris)',
    plate: 'XYZ-9876',
    rating: 4.8,
    status: 'PENDING',
    online: false,
    lat: 19.4270,
    lng: -99.1677,
    docs: {
      license: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400',
      registration: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      soat: 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=400'
    }
  },
  {
    id: 'drv-3',
    name: 'Ana Sofía Rodríguez',
    phone: '+52 55 4567 8901',
    vehicle: 'Kia Rio 2023 (Blanco)',
    plate: 'KLM-4567',
    rating: 5.0,
    status: 'APPROVED',
    online: true,
    lat: 19.4194,
    lng: -99.1556,
    docs: {
      license: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400',
      registration: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400',
      soat: 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=400'
    }
  }
];

const INITIAL_TRIPS = [
  {
    id: 'TRIP-8941',
    passenger: 'Laura Gutiérrez',
    driver: 'Carlos Mendoza',
    origin: 'Polanco, CDMX',
    destination: 'Aeropuerto Terminal 1',
    distance: '14.2 km',
    duration: '28 min',
    totalFare: 14.50,
    commission: 2.18,
    paymentMethod: 'CARD',
    status: 'COMPLETED',
    date: 'Hoy, 11:42 AM'
  },
  {
    id: 'TRIP-8942',
    passenger: 'Miguel Ángel Torres',
    driver: 'Ana Sofía Rodríguez',
    origin: 'Roma Norte',
    destination: 'Santa Fe Centre',
    distance: '11.8 km',
    duration: '35 min',
    totalFare: 16.80,
    commission: 2.52,
    paymentMethod: 'CASH',
    status: 'IN_PROGRESS',
    date: 'En curso'
  }
];

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [drivers, setDrivers] = useState(INITIAL_DRIVERS);
  const [trips, setTrips] = useState(INITIAL_TRIPS);
  const [selectedDriver, setSelectedDriver] = useState(null);
  
  // Parámetros tarifarios editables
  const [settings, setSettings] = useState({
    baseFare: 2.50,
    costPerKm: 0.85,
    costPerMin: 0.20,
    minFare: 3.50,
    commissionPercent: 15.0
  });

  const handleApproveDriver = (driverId) => {
    setDrivers(prev => prev.map(d => d.id === driverId ? { ...d, status: 'APPROVED' } : d));
    setSelectedDriver(null);
  };

  const handleRejectDriver = (driverId) => {
    setDrivers(prev => prev.map(d => d.id === driverId ? { ...d, status: 'REJECTED' } : d));
    setSelectedDriver(null);
  };

  return (
    <div className="flex h-screen bg-dark-900 text-slate-100 font-sans">
      
      {/* SIDEBAR NAVEGACIÓN */}
      <aside className="w-64 glass-panel border-r border-slate-800 flex flex-col">
        <div className="p-6 border-b border-slate-800/80 flex items-center space-x-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-brand-600 to-amber-500 flex items-center justify-center font-extrabold text-xl text-white shadow-lg shadow-brand-500/20">
            T
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-white">TINGO</h1>
            <p className="text-xs text-brand-500 font-medium">Panel Admin ($0/Mes)</p>
          </div>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          <button 
            onClick={() => setActiveTab('dashboard')}
            className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition font-medium text-sm ${activeTab === 'dashboard' ? 'bg-brand-600 text-white shadow-md shadow-brand-600/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white'}`}
          >
            <Activity size={18} />
            <span>Dashboard & Mapa</span>
          </button>

          <button 
            onClick={() => setActiveTab('drivers')}
            className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition font-medium text-sm ${activeTab === 'drivers' ? 'bg-brand-600 text-white shadow-md shadow-brand-600/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white'}`}
          >
            <FileCheck size={18} />
            <span>Validación Conductores</span>
            {drivers.filter(d => d.status === 'PENDING').length > 0 && (
              <span className="ml-auto bg-amber-500 text-dark-900 text-xs px-2 py-0.5 rounded-full font-bold">
                {drivers.filter(d => d.status === 'PENDING').length}
              </span>
            )}
          </button>

          <button 
            onClick={() => setActiveTab('trips')}
            className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition font-medium text-sm ${activeTab === 'trips' ? 'bg-brand-600 text-white shadow-md shadow-brand-600/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white'}`}
          >
            <Navigation size={18} />
            <span>Historial de Viajes</span>
          </button>

          <button 
            onClick={() => setActiveTab('settings')}
            className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl transition font-medium text-sm ${activeTab === 'settings' ? 'bg-brand-600 text-white shadow-md shadow-brand-600/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-white'}`}
          >
            <Settings size={18} />
            <span>Tarifas y Comisiones</span>
          </button>
        </nav>

        <div className="p-4 border-t border-slate-800 text-xs text-slate-500 text-center">
          Servidor: <span className="text-emerald-400 font-semibold">Render Free</span> | Supabase PostGIS
        </div>
      </aside>

      {/* CONTENIDO PRINCIPAL */}
      <main className="flex-1 flex flex-col overflow-y-auto">
        
        {/* TOPBAR */}
        <header className="h-16 border-b border-slate-800/80 px-8 flex items-center justify-between glass-panel sticky top-0 z-20">
          <h2 className="text-lg font-bold text-white uppercase tracking-wider">
            {activeTab === 'dashboard' && 'Monitor en Tiempo Real'}
            {activeTab === 'drivers' && 'Revisión y Aprobación de Conductores'}
            {activeTab === 'trips' && 'Auditoría de Viajes y Cobros'}
            {activeTab === 'settings' && 'Parámetros Globales del Negocio'}
          </h2>

          <div className="flex items-center space-x-4">
            <span className="flex items-center space-x-2 text-xs bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-3 py-1.5 rounded-full">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              <span>PostGIS Realtime Activo</span>
            </span>
            <div className="w-8 h-8 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center font-bold text-sm text-brand-500">
              AD
            </div>
          </div>
        </header>

        <div className="p-8 space-y-8 flex-1">
          
          {/* TAB 1: DASHBOARD */}
          {activeTab === 'dashboard' && (
            <div className="space-y-8">
              {/* CARDS KPI */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <div className="glass-panel p-5 rounded-2xl border border-slate-800 flex items-center space-x-4">
                  <div className="p-3 bg-brand-500/10 text-brand-500 rounded-xl">
                    <Activity size={24} />
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-medium">Viajes Activos Ahora</p>
                    <h3 className="text-2xl font-extrabold text-white mt-1">1</h3>
                  </div>
                </div>

                <div className="glass-panel p-5 rounded-2xl border border-slate-800 flex items-center space-x-4">
                  <div className="p-3 bg-emerald-500/10 text-emerald-400 rounded-xl">
                    <CheckCircle size={24} />
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-medium">Completados Hoy</p>
                    <h3 className="text-2xl font-extrabold text-white mt-1">14</h3>
                  </div>
                </div>

                <div className="glass-panel p-5 rounded-2xl border border-slate-800 flex items-center space-x-4">
                  <div className="p-3 bg-indigo-500/10 text-indigo-400 rounded-xl">
                    <DollarSign size={24} />
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-medium">Facturación Bruta</p>
                    <h3 className="text-2xl font-extrabold text-white mt-1">$194.50</h3>
                  </div>
                </div>

                <div className="glass-panel p-5 rounded-2xl border border-slate-800 flex items-center space-x-4">
                  <div className="p-3 bg-amber-500/10 text-amber-400 rounded-xl">
                    <TrendingUp size={24} />
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-medium">Comisión Tingo (15%)</p>
                    <h3 className="text-2xl font-extrabold text-white mt-1">$29.17</h3>
                  </div>
                </div>
              </div>

              {/* CONTENEDOR DE MAPA Y CONDUCTORES ACTIVOS */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                
                {/* MAPA INTERACTIVO (SIMULACIÓN VISUAL OPENSTREETMAP) */}
                <div className="lg:col-span-2 glass-panel p-4 rounded-2xl border border-slate-800 flex flex-col h-96 relative overflow-hidden">
                  <div className="flex justify-between items-center mb-3">
                    <h3 className="text-sm font-semibold text-slate-300 flex items-center space-x-2">
                      <MapPin size={16} className="text-brand-500" />
                      <span>Mapa Global de Conductores Conectados (OpenStreetMap)</span>
                    </h3>
                    <span className="text-xs text-slate-500">CDMX Geo-bounds</span>
                  </div>

                  <div className="flex-1 rounded-xl bg-slate-950 border border-slate-800/80 relative flex items-center justify-center p-6 text-center">
                    {/* Visual Mock Map overlay */}
                    <div className="absolute inset-0 bg-[radial-gradient(#1f293d_1px,transparent_1px)] [background-size:16px_16px] opacity-40"></div>
                    
                    {/* Simulated Map Markers */}
                    {drivers.filter(d => d.online).map((drv, idx) => (
                      <div 
                        key={drv.id}
                        className="absolute transform -translate-x-1/2 -translate-y-1/2 flex flex-col items-center group cursor-pointer"
                        style={{ top: `${35 + idx * 25}%`, left: `${40 + idx * 20}%` }}
                      >
                        <div className="w-8 h-8 rounded-full bg-brand-500 border-2 border-white flex items-center justify-center shadow-lg shadow-brand-500/40 text-white">
                          <Car size={16} />
                        </div>
                        <span className="mt-1 text-[10px] font-bold bg-dark-900/90 text-slate-200 px-2 py-0.5 rounded border border-slate-700 shadow">
                          {drv.name.split(' ')[0]} ({drv.plate})
                        </span>
                      </div>
                    ))}

                    <div className="z-10 text-slate-400">
                      <p className="font-medium text-sm text-slate-200">Visor de Mapa Realtime Conectado a Supabase PostGIS</p>
                      <p className="text-xs text-slate-500 mt-1">Transmisión por WebSockets activa cada 20m de distancia</p>
                    </div>
                  </div>
                </div>

                {/* LISTA DE CONDUCTORES EN LÍNEA */}
                <div className="glass-panel p-5 rounded-2xl border border-slate-800 flex flex-col">
                  <h3 className="text-sm font-semibold text-slate-200 mb-4 flex items-center justify-between">
                    <span>Conductores Conectados</span>
                    <span className="bg-slate-800 text-brand-400 text-xs px-2.5 py-1 rounded-full font-bold">
                      {drivers.filter(d => d.online).length} en servicio
                    </span>
                  </h3>

                  <div className="space-y-3 overflow-y-auto max-h-80 pr-1">
                    {drivers.map(driver => (
                      <div key={driver.id} className="p-3 bg-slate-800/40 rounded-xl border border-slate-800 flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                          <div className="w-9 h-9 rounded-full bg-slate-700 flex items-center justify-center text-sm font-bold text-slate-200">
                            {driver.name.substring(0, 2).toUpperCase()}
                          </div>
                          <div>
                            <p className="text-sm font-semibold text-white">{driver.name}</p>
                            <p className="text-xs text-slate-400">{driver.vehicle}</p>
                          </div>
                        </div>

                        <div className="text-right">
                          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${driver.online ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-700 text-slate-400'}`}>
                            {driver.online ? 'En Línea' : 'Desconectado'}
                          </span>
                          <p className="text-xs text-amber-400 font-semibold mt-1">★ {driver.rating}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

              </div>
            </div>
          )}

          {/* TAB 2: APROBACIÓN DE CONDUCTORES */}
          {activeTab === 'drivers' && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <p className="text-sm text-slate-400">Revisa la documentación obligatoria (Licencia, Tarjeta de Circulación y SOAT) antes de activar conductores en la plataforma.</p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {drivers.map(driver => (
                  <div key={driver.id} className="glass-panel p-6 rounded-2xl border border-slate-800 flex flex-col justify-between space-y-4">
                    <div>
                      <div className="flex justify-between items-start">
                        <div>
                          <h4 className="text-lg font-bold text-white">{driver.name}</h4>
                          <p className="text-xs text-slate-400">{driver.phone}</p>
                        </div>
                        <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${
                          driver.status === 'APPROVED' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' :
                          driver.status === 'PENDING' ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' : 'bg-rose-500/20 text-rose-400'
                        }`}>
                          {driver.status === 'APPROVED' ? 'APROBADO' : driver.status === 'PENDING' ? 'EN REVISIÓN' : 'RECHAZADO'}
                        </span>
                      </div>

                      <div className="mt-4 p-3 bg-slate-900/60 rounded-xl border border-slate-800 space-y-1 text-xs text-slate-300">
                        <p><span className="text-slate-500">Auto:</span> {driver.vehicle}</p>
                        <p><span className="text-slate-500">Placas:</span> {driver.plate}</p>
                      </div>
                    </div>

                    <div className="pt-2 flex items-center space-x-2">
                      <button 
                        onClick={() => setSelectedDriver(driver)}
                        className="flex-1 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs py-2.5 rounded-xl font-medium transition"
                      >
                        Ver Documentos
                      </button>

                      {driver.status === 'PENDING' && (
                        <>
                          <button 
                            onClick={() => handleApproveDriver(driver.id)}
                            className="bg-emerald-600 hover:bg-emerald-500 text-white text-xs px-3 py-2.5 rounded-xl font-medium transition"
                          >
                            Aprobar
                          </button>
                          <button 
                            onClick={() => handleRejectDriver(driver.id)}
                            className="bg-rose-600 hover:bg-rose-500 text-white text-xs px-3 py-2.5 rounded-xl font-medium transition"
                          >
                            Rechazar
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* TAB 3: HISTORIAL DE VIAJES */}
          {activeTab === 'trips' && (
            <div className="glass-panel p-6 rounded-2xl border border-slate-800 space-y-4">
              <div className="flex justify-between items-center">
                <h3 className="text-base font-bold text-white">Registro de Viajes</h3>
                <div className="relative">
                  <Search size={16} className="absolute left-3 top-2.5 text-slate-500" />
                  <input 
                    type="text" 
                    placeholder="Buscar viaje o pasajero..."
                    className="bg-slate-900 border border-slate-800 text-xs text-slate-200 pl-9 pr-4 py-2 rounded-xl focus:outline-none focus:border-brand-500"
                  />
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-300">
                  <thead className="bg-slate-900/80 text-slate-400 uppercase text-[10px] tracking-wider border-b border-slate-800">
                    <tr>
                      <th className="p-3">ID Viaje</th>
                      <th className="p-3">Pasajero</th>
                      <th className="p-3">Conductor</th>
                      <th className="p-3">Ruta</th>
                      <th className="p-3">Monto Total</th>
                      <th className="p-3">Comisión Tingo (15%)</th>
                      <th className="p-3">Pago</th>
                      <th className="p-3">Estado</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {trips.map(trip => (
                      <tr key={trip.id} className="hover:bg-slate-800/30 transition">
                        <td className="p-3 font-mono font-bold text-brand-400">{trip.id}</td>
                        <td className="p-3 font-medium text-white">{trip.passenger}</td>
                        <td className="p-3 text-slate-300">{trip.driver}</td>
                        <td className="p-3 max-w-xs truncate">{trip.origin} ➔ {trip.destination}</td>
                        <td className="p-3 font-bold text-white">${trip.totalFare.toFixed(2)}</td>
                        <td className="p-3 font-bold text-amber-400">${trip.commission.toFixed(2)}</td>
                        <td className="p-3">
                          <span className={`px-2 py-0.5 rounded font-bold text-[10px] ${trip.paymentMethod === 'CARD' ? 'bg-indigo-500/20 text-indigo-400' : 'bg-emerald-500/20 text-emerald-400'}`}>
                            {trip.paymentMethod === 'CARD' ? 'TARJETA STRIPE' : 'EFECTIVO'}
                          </span>
                        </td>
                        <td className="p-3">
                          <span className={`px-2 py-0.5 rounded-full font-bold text-[10px] ${trip.status === 'COMPLETED' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'}`}>
                            {trip.status === 'COMPLETED' ? 'COMPLETADO' : 'EN CURSO'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 4: CONFIGURACIÓN DE TARIFAS */}
          {activeTab === 'settings' && (
            <div className="max-w-2xl glass-panel p-6 rounded-2xl border border-slate-800 space-y-6">
              <div>
                <h3 className="text-base font-bold text-white">Configuración del Modelo Financiero Tingo</h3>
                <p className="text-xs text-slate-400 mt-1">Ajusta las tarifas que se ejecutan localmente en el teléfono del pasajero y el backend.</p>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Tarifa Base ($ USD)</label>
                  <input 
                    type="number" 
                    step="0.10"
                    value={settings.baseFare}
                    onChange={e => setSettings({ ...settings, baseFare: parseFloat(e.target.value) })}
                    className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:border-brand-500 focus:outline-none"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1">Costo por Kilómetro ($)</label>
                    <input 
                      type="number" 
                      step="0.05"
                      value={settings.costPerKm}
                      onChange={e => setSettings({ ...settings, costPerKm: parseFloat(e.target.value) })}
                      className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:border-brand-500 focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1">Costo por Minuto ($)</label>
                    <input 
                      type="number" 
                      step="0.05"
                      value={settings.costPerMin}
                      onChange={e => setSettings({ ...settings, costPerMin: parseFloat(e.target.value) })}
                      className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:border-brand-500 focus:outline-none"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1">Tarifa Mínima por Viaje ($)</label>
                    <input 
                      type="number" 
                      step="0.50"
                      value={settings.minFare}
                      onChange={e => setSettings({ ...settings, minFare: parseFloat(e.target.value) })}
                      className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:border-brand-500 focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1">Comisión de la App Tingo (%)</label>
                    <input 
                      type="number" 
                      step="1.0"
                      value={settings.commissionPercent}
                      onChange={e => setSettings({ ...settings, commissionPercent: parseFloat(e.target.value) })}
                      className="w-full bg-slate-900 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:border-brand-500 focus:outline-none"
                    />
                  </div>
                </div>

                <button 
                  onClick={() => alert('¡Tarifas guardadas exitosamente en Supabase!')}
                  className="w-full bg-brand-600 hover:bg-brand-500 text-white font-bold py-3 rounded-xl transition shadow-lg shadow-brand-600/30 text-sm"
                >
                  Guardar Cambios de Tarifa
                </button>
              </div>
            </div>
          )}

        </div>
      </main>

      {/* MODAL DE VISUALIZACIÓN DE DOCUMENTOS DEL CONDUCTOR */}
      {selectedDriver && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="glass-panel p-6 rounded-2xl max-w-lg w-full border border-slate-700 space-y-4">
            <div className="flex justify-between items-center border-b border-slate-800 pb-3">
              <h3 className="text-base font-bold text-white">Documentación: {selectedDriver.name}</h3>
              <button onClick={() => setSelectedDriver(null)} className="text-slate-400 hover:text-white font-bold">✕</button>
            </div>

            <div className="space-y-3">
              <div>
                <p className="text-xs text-slate-400 font-semibold mb-1">Licencia de Conducir Válida</p>
                <img src={selectedDriver.docs.license} alt="Licencia" className="w-full h-36 object-cover rounded-xl border border-slate-800" />
              </div>
              <div>
                <p className="text-xs text-slate-400 font-semibold mb-1">Tarjeta de Circulación</p>
                <img src={selectedDriver.docs.registration} alt="Tarjeta Circulacion" className="w-full h-36 object-cover rounded-xl border border-slate-800" />
              </div>
            </div>

            <div className="pt-2 flex justify-end space-x-3">
              <button 
                onClick={() => setSelectedDriver(null)}
                className="px-4 py-2 bg-slate-800 text-slate-300 text-xs rounded-xl hover:bg-slate-700"
              >
                Cerrar Visor
              </button>
              <button 
                onClick={() => handleApproveDriver(selectedDriver.id)}
                className="px-4 py-2 bg-emerald-600 text-white text-xs rounded-xl font-bold hover:bg-emerald-500"
              >
                Aprobar Documentos
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
