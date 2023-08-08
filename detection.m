close all

last_fr = {[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]}; % este array vai conter todos os centroides das regioes das ultimas 15 frames - usado para traçar trajetorias dinamicas

% ------ arrays para calcular labels ------ %
bbox_last_fr = {}; % este array vai conter as bounding boxes de todas as regioes da ultima frame visitada
idx_last_fr = []; % array com indices das regioes da ultima frame visitada
bbox_curr_fr = {}; % este array vai conter as bounding boxes de todas as regioes da frame em que estamos
idx_curr_fr = []; % este array vai conter os indices das regioes da bbox_last_fr com as quais cada umas das novas regioes interseta
% --------------------------------------- %

path = 'View_001/';

nFrames = size(dir([path '/*.jpg']), 1); %dir da-nos uma lista com os nomes de todas as frames .jpg e o size da-nos o numero de frames
I_over_O = zeros(nFrames, 1); % para guardar as intersections over unions das regions de todas as frames

% as proximas duas linhas foram calculadas aqui para conseguirmos criar o Bkg com o tamanho das frames
strFrame = sprintf('%s%s%.4d.%s', path, 'frame_', 0, 'jpg'); %string com o nome da primeira frame
I = imread(strFrame);
Bkg = zeros(size(I)); %imagem a zeros (inicialmente) do tamanho das nossas frames

% ---------------------- Calculo da background image ---------------------- %
% Deixamos este codigo comentado pois subtemos tambem a background image ja
% calculada atraves deste codigo, dado que eh um processo muito demorado. 
% No entanto, pode ser descomentado e funciona na mesma. 

% alfa = 0.005;
% for i=0:(nFrames-1) %vamos percorrer todas as frames
%     strFrame = sprintf('%s%s%.4d.%s', path, 'frame_', i, 'jpg');
%     Y = imread(strFrame);
%     Bkg = alfa * double(Y) + (1-alfa) * double(Bkg);
%     imagesc(uint8(Bkg)); axis ij, drawnow
% end
% 
% imwrite(uint8(Bkg), 'bkg.png');
% ------------------------------------------------------------------------- %

imgbk = imread('bkg.png');
imgMap = zeros(size(imgbk, 1), size(imgbk, 2));
imgTraj = imread('bkg.png');

thr = 75;
minArea = 200;

se = strel('disk', 3);

figure;
for i=0:(nFrames-1) % ler frames sequencialmente e para cada imagem calcular a diferença com a imagem de background 
    
    strFrame = sprintf('%s%s%.4d.%s', path, 'frame_', i, 'jpg');
    imgfr = imread(strFrame); %para ir buscar cada imagem
    subplot(1,2,1); imshow(imgfr); title('Pedestrian Detection'); hold on;
    
    
    % ------------- regioes detetadas por nós para esta frame ------------- %
    imgdif = (abs(double(imgbk(:,:,1))-double(imgfr(:,:,1))) > thr) | (abs(double(imgbk(:,:,2))-double(imgfr(:,:,2))) > thr) | (abs(double(imgbk(:,:,3))-double(imgfr(:,:,3))) > thr);
    % imgdif só fica ativo (a 1) no sítio das onde há movimento aka onde há
    % diferenças

    bw = imclose(imgdif, se); %aplicar operação morfológica para limpara as regiões um bocadinho melhor
    % mesmo assim acusa muitas regiões ativas que são ruído - regionprops:
    
    [lb num] = bwlabel(bw);
    regionProps = regionprops(lb, 'Area', 'BoundingBox', 'FilledImage', 'Centroid');
    inds = find([regionProps.Area] > minArea); % guarda os indices das regiões que satisfazem a condição
    
    last_fr{rem(i,15)+1} = []; % rem(i,15)+1=[] eh a forma de acedermos ciclicamente ah posicao do array que foi atualizada ha mais tempo e limpar os centroids associados a essa frame; 
    
    bbox_curr_fr = []; %vamos guardar as bounding boxes das regioes desta frame
    idx_curr_fr = []; %e aqui guardamos os indices com as quais essas bounding boxes intersetam
    
    for j=1:length(inds)
        [lin col] = find(lb == inds(j)); % devolve todas as posições [y x] da região 
        upLPoint = min([lin col]); % devolve y, x
        dWindow = max([lin col]) - upLPoint + 1; % devolve height, width
        box = [fliplr(upLPoint) fliplr(dWindow)]; %fliplr porque precisamos que position = [x y w h]
        
        rectangle('Position', box, 'EdgeColor', [1 1 1], 'linewidth', 2); 
        
        % ---------------- Calculo das labels dos pedestres --------------- %
        if i ~= 0 % a partir da segunda frame, temos que comparar as suas regioes com as da frame anterior
            overlap = false; %overlap so vai ser true se houver intersecao da nossa regiao atual com alguma regiao da frame anterior
            maximo = 0; % para guardar maior intersecao 
            idx_maximo = 0; %guarda a label da regiao onde verificamos maior intersecao 
            % idx_r = 0;
            
            % --- ciclo for para encontrar a regiao da frame anterior com a qual a nossa regiao atual tem maior intersecao
            for r=1:length(bbox_last_fr) %para cada regiao da frame anterior
                if rectint(box, bbox_last_fr{r}) > maximo % quer dizer que encontramos uma regiao com intersecao maior
                    overlap = true;
                    maximo = rectint(box, bbox_last_fr{r}); 
                    idx_maximo = idx_last_fr(r); %quando ha intersecao, indices deverao ser iguais pois terao a mesma label
                    % idx_r = r; % queremos guardar o r para, no calculo da trajetoria, conseguirmos ir buscar a regiao em bbox_last_fr que esta na posicao r
                end
            end
            
            % --- if para, quando nao foi detetada nenhuma intersecao, as in, estamos na presenca de uma nova regiao, lhe atribuirmos uma nova label
            if overlap == false 
                if j ~= 1 % para as restantes regioes da frame
                    idx_maximo = max(max(idx_last_fr), max(idx_curr_fr)) + 1; % a nova regiao fica com uma nova label, imediatamente a seguir ah label mais alta que ja existia
                else % para a primeira regiao da frame (pois nesta regiao o idx_curr_fr esta vazio, logo, a nova label eh apenas o valor imediatamente a seguir ah maior label da frame passada)
                    idx_maximo = max(idx_last_fr) + 1;
                end
%             else 
%                 last = bbox_last_fr{idx_r}; % last eh a regiao na bbox_last_fr que eh analoga ah regiao em questao (i.e. box)
%                 centroid_x = [(last(1)+(last(3)/2)) (box(1)+(box(3)/2))];
%                 centroid_y = [(last(2)+(last(4)/2)) (box(2)+(box(4)/2))];
%                 plot(centroid_x, centroid_y, 'w-');
            end
            
            bbox_curr_fr{end+1} = box; % atualizacao do vetor de bounding boxes com a regiao atual
            idx_curr_fr(end+1) = idx_maximo; % atualizacao do vetor de labels com a label atribuida ah regiao atual
            text(regionProps(inds(j)).Centroid(1), regionProps(inds(j)).Centroid(2)-(regionProps(inds(j)).BoundingBox(4)/2)-10, num2str(idx_curr_fr(end)), 'Color', [0.949 0.949 0.949],'FontSize', 20);
            
        else % else para a primeira frame
            bbox_curr_fr{end+1} = box; %para a primeira frame, apenas guardamos a bounding box de cada regiao (nao precisamos de comparar com regioes da frame anterior)
            idx_curr_fr(end+1) = j; %labels na primeira frame correspondem ah ordem em que vemos as regioes
            text(regionProps(inds(j)).Centroid(1), regionProps(inds(j)).Centroid(2)-(regionProps(inds(j)).BoundingBox(4)/2)-10, num2str(j), 'Color', [0.949 0.949 0.949],'FontSize', 20);
        end
        % ----------------------------------------------------------------- %
        

        % ---- Calculo dos centroides dos pedestres nas ultimas 15 frames (trajetorias DINAMICAS) --- %
        last_fr{rem(i,15)+1}(end+1) = regionProps(inds(j)).Centroid(1); % onde limpamos os centroides da frame mais antiga, escrevemos agora os centroides da frame mais recente
        last_fr{rem(i,15)+1}(end+1) = regionProps(inds(j)).Centroid(2);
        % ------------------------------------------------------------------------------------------- %
        
    end
    
    % quando acabamos o calculo das regioes atuais e suas labels, guardamos ambas nos vetores last_fr para que possam ser usadas na frame seguinte
    bbox_last_fr = bbox_curr_fr; 
    idx_last_fr = idx_curr_fr;
    
    
    % ----------------- Imprimir trajetorias DINAMICAS -------------------- %
    n_fr = min(i+1, 15); %para evitar que, nas primeiras 3 frames, tentemos acessar os centroides de frames que ainda não visitamos
    for f=1:n_fr
        plot(last_fr{f}([1:2:length(last_fr{f})]), last_fr{f}([2:2:length(last_fr{f})]), 'w*'); % plot das trajetorias dinâmicas
    end
    % --------------------------------------------------------------------- %
    
    drawnow
    
    
    % ---------- trajetorias TOTAIS realizadas pelos pedestres ------------ %
    for k=1:length(inds) 
        centroid_x = round(regionProps(inds(k)).Centroid(1));
        centroid_y = round(regionProps(inds(k)).Centroid(2));
        imgTraj(centroid_y-1:centroid_y+1, centroid_x-1:centroid_x+1, 1) = 255;
        imgTraj(centroid_y-1:centroid_y+1, centroid_x-1:centroid_x+1, 2:3) = 0;
    end
    subplot(1,2,2); imshow(imgTraj); title('Performed Trajectories');
    % --------------------------------------------------------------------- %
    
end
