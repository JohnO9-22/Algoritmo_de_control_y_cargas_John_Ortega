
% PROYECTO: Sistema Inteligente de Gestion Energetica (SIGE)
% RETO 3: Algoritmo de control y cargas
% Curso: Software para Ingenieria
% Simulacion de 24 horas del balance energetico de una microred.
% Estudiante: John Ortega

clear;
clc;
close all;

%% 1. CONFIGURACION INICIAL
horas = 1:24;
numero_horas = 24;

capacidad_bateria = 100;
SOC_inicial = 50;
SOC = SOC_inicial;

SOC_minimo = 0;
SOC_maximo = 100;

% Vectores para guardar resultados de cada hora.
SOC_historico = zeros(1, numero_horas);
generacion_historico = zeros(1, numero_horas);
demanda_historico = zeros(1, numero_horas);
balance_historico = zeros(1, numero_horas);
excedente_historico = zeros(1, numero_horas);
faltante_historico = zeros(1, numero_horas);

% Estado inicial de los servicios.
escuela = true;
bombeo = true;
alumbrado = true;

estado_escuela = false(1, numero_horas);
estado_bombeo = false(1, numero_horas);
estado_alumbrado = false(1, numero_horas);

%% 2. GENERACION SOLAR
P_max_solar = 25;
generacion_solar = zeros(1, 24);
horas_dia = 6:18;

generacion_solar(horas_dia) = P_max_solar * ...
    sin(pi * (horas_dia - 6) / 12);

generacion_solar([1:5, 19:24]) = 0;

%% 3. GENERACION EOLICA
P_max_eolica = 15;
rng(7);

tendencia_viento = 7 + 4 * ...
    sin(2 * pi * horas / 9 + 1.5);

rafagas = 3 * randn(1, 24);
generacion_eolica = tendencia_viento + rafagas;
generacion_eolica = max(generacion_eolica, 0);
generacion_eolica = min(generacion_eolica, P_max_eolica);

%% 4. DEMANDA DE LA COMUNIDAD
demanda = zeros(1, 24);

horas_min = [1:5, 22:24];
demanda(horas_min) = 2 + (4 - 2) * ...
    rand(1, length(horas_min));

horas_diurnas = 6:17;
demanda(horas_diurnas) = 6 + (10 - 6) * ...
    rand(1, length(horas_diurnas));

horas_pico = 18:21;
perfil_pico = [12, 15, 15, 13];
demanda(horas_pico) = perfil_pico;

%% 5. CALCULO DE LA GENERACION HIBRIDA
generacion_total = generacion_solar + generacion_eolica;

%% 6. SIMULACION DEL CONTROL DURANTE 24 HORAS

% REPORTE HORIZONTAL: UNA FILA POR CADA HORA
fprintf('\n');
fprintf('===============================================================================================================\n');
fprintf('                    REPORTE HORARIO DEL CONTROL ENERGETICO SIGE - RETO 3\n');
fprintf('===============================================================================================================\n');
fprintf('Capacidad bateria: %.2f kWh | SOC inicial: %.2f %% | Horas simuladas: %d\n\n', ...
    capacidad_bateria, SOC_inicial, numero_horas);

fprintf('Hora | Generacion | Demanda | Balance | SOC (%%) | Escuela | Bombeo | Alumbrado\n');
fprintf('-----|------------|---------|---------|---------|---------|--------|----------\n');

% Ciclo completo de 24 horas.
hora = 1;

while hora <= numero_horas

    Egen = generacion_total(hora);
    Edem = demanda(hora);

    % Calcular balance energetico.
    balance = Egen - Edem;

    excedente = 0;
    faltante = 0;

    %% 6.1. DECISION SEGUN EL BALANCE ENERGETICO
    if balance >= 0

        % Superavit: almacenar el excedente.
        excedente = balance;
        SOC = SOC + (excedente / capacidad_bateria) * 100;

        % Limitar SOC entre 0 % y 100 %.
        SOC = min(max(SOC, SOC_minimo), SOC_maximo);

        escuela = true;
        bombeo = true;
        alumbrado = true;

    else

        % Deficit: descontar la energia faltante.
        faltante = abs(balance);
        SOC = SOC - (faltante / capacidad_bateria) * 100;

        % Limitar SOC entre 0 % y 100 %.
        SOC = min(max(SOC, SOC_minimo), SOC_maximo);

        %% 6.2. CONTROL DE PRIORIDAD DE LAS CARGAS
        if SOC > 40

            % Rango seguro.
            escuela = true;
            bombeo = true;
            alumbrado = true;

        elseif SOC > 20

            % Rango de alerta: desconectar alumbrado.
            escuela = true;
            bombeo = true;
            alumbrado = false;

        else

            % Rango de emergencia: desconectar alumbrado y bombeo.
            escuela = true;
            bombeo = false;
            alumbrado = false;

        end
    end

    %% 6.3. VALIDAR SOC Y REGISTRAR RESULTADOS
    SOC = min(max(SOC, SOC_minimo), SOC_maximo);

    assert(SOC >= SOC_minimo && SOC <= SOC_maximo, ...
        'Error: SOC fuera del intervalo permitido en la hora %d.', hora);

    SOC_historico(hora) = SOC;
    generacion_historico(hora) = Egen;
    demanda_historico(hora) = Edem;
    balance_historico(hora) = balance;
    excedente_historico(hora) = excedente;
    faltante_historico(hora) = faltante;

    estado_escuela(hora) = escuela;
    estado_bombeo(hora) = bombeo;
    estado_alumbrado(hora) = alumbrado;

    %% 6.4. REPORTE HORIZONTAL
    if escuela
        texto_escuela = 'ACTIVA';
    else
        texto_escuela = 'OFF';
    end

    if bombeo
        texto_bombeo = 'ACTIVO';
    else
        texto_bombeo = 'OFF';
    end

    if alumbrado
        texto_alumbrado = 'ACTIVO';
    else
        texto_alumbrado = 'OFF';
    end

    % Imprimir todos los datos en una sola fila.
    fprintf('%4d | %10.2f | %7.2f | %7.2f | %7.2f | %-7s | %-6s | %-8s\n', ...
        hora, Egen, Edem, balance, SOC, ...
        texto_escuela, texto_bombeo, texto_alumbrado);

    % Incrementar el contador de hora.
    hora = hora + 1;
end

%% 7. RESUMEN FINAL
fprintf('\n===============================================================================================================\n');
fprintf('                                      RESUMEN FINAL DEL SIGE\n');
fprintf('===============================================================================================================\n');

fprintf('SOC inicial: %.2f %% | SOC final: %.2f %% | SOC minimo: %.2f %% | SOC maximo: %.2f %%\n', ...
    SOC_inicial, SOC_historico(end), ...
    min(SOC_historico), max(SOC_historico));

% Verificar el SOC durante las 24 horas.
if all(SOC_historico >= SOC_minimo & ...
       SOC_historico <= SOC_maximo)

    fprintf('VERIFICACION CORRECTA: SOC entre 0%% y 100%%.\n');

else
    error('Se detecto un SOC fuera del intervalo permitido.');
end

fprintf('Horas con superavit: %2d | Horas con deficit: %2d\n', ...
    sum(balance_historico >= 0), ...
    sum(balance_historico < 0));

fprintf('Alumbrado suspendido: %2d horas | Bombeo suspendido: %2d horas | Escuela activa: %2d horas\n', ...
    sum(~estado_alumbrado), ...
    sum(~estado_bombeo), ...
    sum(estado_escuela));

%% 8. GRAFICA DEL ESTADO DE CARGA DE LA BATERIA
figure('Name', 'Control de bateria SIGE - Reto 3', ...
    'NumberTitle', 'off');

plot(horas, SOC_historico, '-o', 'LineWidth', 2);
hold on;

yline(40, '--', 'Limite de alerta: 40 %');
yline(20, '--', 'Limite de emergencia: 20 %');
yline(100, ':', 'Carga maxima: 100 %');
yline(0, ':', 'Carga minima: 0 %');

hold off;

title('Estado de carga de la bateria durante 24 horas');
xlabel('Hora del dia');
ylabel('Estado de carga SOC (%)');

xticks(1:24);
xlim([1 24]);
ylim([0 100]);
grid on;

%% 9. GRAFICA DEL BALANCE ENERGETICO
figure('Name', 'Balance energetico SIGE - Reto 3', ...
    'NumberTitle', 'off');

bar(horas, balance_historico);

title('Balance energetico por hora');
xlabel('Hora del dia');
ylabel('Balance (kW)');

xticks(1:24);
xlim([0 25]);
yline(0, '-k');
grid on;

fprintf('\nSimulacion de 24 horas finalizada.\n');
