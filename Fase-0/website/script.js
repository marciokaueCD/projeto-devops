const STATUS_LABELS = {
  ok: 'operacional',
  degraded: 'degradado',
  down: 'indisponível',
};

const REFRESH_INTERVAL_MS = 10000;

function updateClock() {
  const now = new Date();
  const clock = document.getElementById('clock');
  clock.textContent = now.toLocaleTimeString('pt-BR', { hour12: false });
}

function timeAgoLabel(offsetSeconds) {
  if (offsetSeconds < 60) return `há ${offsetSeconds}s`;
  const minutes = Math.floor(offsetSeconds / 60);
  return `há ${minutes}min`;
}

function renderRows(services) {
  const container = document.getElementById('rows');
  container.innerHTML = '';

  services.forEach((service, index) => {
    const row = document.createElement('div');
    row.className = 'row';
    row.style.animationDelay = `${index * 60}ms`;

    const latencyLabel = service.status === 'down' ? '—' : `${service.latency}ms`;
    const checkOffset = Math.floor(Math.random() * 45) + 1;

    row.innerHTML = `
      <span class="row__service">${service.name}</span>
      <span class="badge badge--${service.status}">${STATUS_LABELS[service.status]}</span>
      <span class="row__latency">${latencyLabel}</span>
      <span class="row__uptime">${service.uptime.toFixed(2)}%</span>
      <span class="row__check">${timeAgoLabel(checkOffset)}</span>
    `;

    container.appendChild(row);
  });

  updateSummary(services);
}

function updateSummary(services) {
  const summary = document.getElementById('summary');
  const downCount = services.filter((s) => s.status === 'down').length;
  const degradedCount = services.filter((s) => s.status === 'degraded').length;

  if (downCount > 0) {
    summary.textContent = `${downCount} serviço(s) indisponível(is)`;
  } else if (degradedCount > 0) {
    summary.textContent = `${degradedCount} serviço(s) degradado(s)`;
  } else {
    summary.textContent = 'todos os sistemas operacionais';
  }
}

async function loadServices() {
  try {
    const response = await fetch('services.json');
    const services = await response.json();
    renderRows(services);
  } catch (error) {
    document.getElementById('summary').textContent = 'erro ao carregar serviços';
    console.error('Falha ao carregar services.json', error);
  }
}

document.getElementById('interval-label').textContent = `${REFRESH_INTERVAL_MS / 1000}s`;

updateClock();
setInterval(updateClock, 1000);

loadServices();
setInterval(loadServices, REFRESH_INTERVAL_MS);
