close all

gt = xml2struct('PETS2009-S2L1.xml');

path = 'View_001/';

nFrames = size(dir([path '/*.jpg']), 1); %dir da-nos uma lista com os nomes de todas as frames .jpg e o size da-nos o numero de frames

IoU_regs = {}; % para guardar as IoU das regions da frame atual
thr_success = zeros(21, 1); % cada posicao corresponde a um threshold de 0 a 1 com step de 0.05

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

thr = 75;
minArea = 200;

se = strel('disk', 3);

figure;
for i=0:(nFrames-1) % ler frames sequencialmente e para cada imagem calcular a diferença com a imagem de background 
    
    strFrame = sprintf('%s%s%.4d.%s', path, 'frame_', i, 'jpg');
    imgfr = imread(strFrame); %para ir buscar cada imagem
    subplot(1,2,1); imshow(imgfr); title('Detected pedestrians (white) VS ground truth (yellow)'); hold on; 
    
    
    % -------------- regioes do ground truth para esta frame -------------- %
    gt_regs = zeros(20,4); % vetor onde guardamos as bounding boxes de cada regiao do ground truth
    n=0;
    
    frame = gt.Children((2*i)+2);
    regionsList = frame.Children(2); %regionsList contem as regioes do ground truth
    
    %Vamos iterar sobre todas as regiões de regionsList para pintarmos as suas boxes
    for j=2:2:length(regionsList.Children)
        region = regionsList.Children(j);
        boundingBox = region.Children(2).Attributes; % boundingBox tem o nome e o valor das coordenadas da box
        
        w = str2double(boundingBox(2).Value);
        h = str2double(boundingBox(1).Value);
        x = str2double(boundingBox(3).Value)-(w/2);
        y = str2double(boundingBox(4).Value)-(h/2);
        
        rectangle('Position', [x y w h], 'EdgeColor', [1 1 0], 'linewidth', 2);        
        
        gt_regs(n+1, 1) = x;
        gt_regs(n+1, 2) = y;
        gt_regs(n+1, 3) = w;
        gt_regs(n+1, 4) = h;
        n = n+1;        
    
    end    

    gt_regs = gt_regs(1:n,:);
    % --------------------------------------------------------------------- %
    
    
    % ------------- regioes detetadas por nós para esta frame ------------- %
    imgdif = (abs(double(imgbk(:,:,1))-double(imgfr(:,:,1))) > thr) | (abs(double(imgbk(:,:,2))-double(imgfr(:,:,2))) > thr) | (abs(double(imgbk(:,:,3))-double(imgfr(:,:,3))) > thr);
    % imgdif só fica ativo (a 1) no sítio das onde há movimento aka onde há
    % diferenças

    bw = imclose(imgdif, se); %aplicar operação morfológica para limpara as regiões um bocadinho melhor
    % mesmo assim acusa muitas regiões ativas que são ruído - regionprops:
    
    [lb num] = bwlabel(bw);
    regionProps = regionprops(lb, 'Area', 'BoundingBox', 'FilledImage', 'Centroid');
    inds = find([regionProps.Area] > minArea); % guarda os indices das regiões que satisfazem a condição
    
    IoU_regs = []; % vetor eh limpo para cada frame, para que os valores correspondem apenas as IoU das regioes da frame atual
    for j=1:length(inds)
        [lin col] = find(lb == inds(j)); % devolve todas as posições [y x] da região 
        upLPoint = min([lin col]); % devolve y, x
        dWindow = max([lin col]) - upLPoint + 1; % devolve height, width
        box = [fliplr(upLPoint) fliplr(dWindow)];
    
        rectangle('Position', box, 'EdgeColor', [1 1 1], 'linewidth', 2); %fliplr porque precisamos que position = [x y w h]
        
        % ----------- IoU das regioes da frame atual ----------- %
        max_intersection = 0; % variavel serve para guardar o valor de intersecao entre a regiao, pois este valor eh necessario para calcular a union e a IoU
        max_box_gt = []; %variavel serve para guardar a bounding box da regiao do ground truth que interseta com a nossa regiao detetada: para calcular a union
        i_o_u = 0; % para calcular IoU= intersection/union; quando nao ha intersecao, esta variavel nao eh atualizada e IoU da regiao em questao eh zero
        
        for d=1:size(gt_regs, 1) % gt_regs tem as b_boxes das regions do ground truth e queremos iterar sobre cada regiao do gt para encontrar aquela que interseta com a noss regiao detetada
            box_gt = [gt_regs(d, 1) gt_regs(d, 2) gt_regs(d, 3) gt_regs(d, 4)]; % guarda a bounding box da regiao do ground truth que estamos a testar agora
            intersection = rectint(box, box_gt); %rectint calcula a area de intersecao entre as duas regioes dadas
            if intersection > max_intersection % se encontrarmos uma regiao do ground truth com a qual a regiao detetada por nos tenha uma maior intersecao
                max_intersection = intersection; % vamos passar a considerar essa regiao para o calculo do IoU, descartando a anterior que tinha menor intersecao
                max_box_gt = box_gt; %max_box_gt contem a bounding box da regiao com a qual ha maior intersecao ate ao momento
            end
        end
        
        if max_intersection ~= 0 % havendo intersecao da nossa regiao detetada com uma regiao do ground truth, calculamos o IoU da regiao
            union = (box(3) * box(4)) + (max_box_gt(3) * max_box_gt(4)) - max_intersection; 
            i_o_u = max_intersection/union;
        end
        IoU_regs(end+1) = i_o_u;    

        % ----------------------------------------------------- %
        
    end
    
    
    % --------------- IoU da frame atual para cada threshold -------------- %
    for t=1:length(thr_success) % para cada threshold
        var = 0;
        thresh = (t-1)*0.05; 
        for region=1:length(IoU_regs)
            if IoU_regs(region) >= thresh
                var = var + 1; % contamos as regioes da frame atual cuja IoU eh maior ou igual ao threshold
            end
        end
        thr_success(t) = thr_success(t)+ (var/length(IoU_regs)); % calculamos o IoU da frame (ao dividirmos o var pelo numero de regioes) e somamo-lo na posicao do threshold em questao.
                                                                 % somamos aqui para que, no final, so tenhamos que dividir pelo numero
                                                                    % total de frames, em vez de termos (no final) que somar todos os
                                                                    % valores e so depois fazer a divisao
    end
    % --------------------------------------------------------------------- %
    
    drawnow
    
end

thr_success = (thr_success/nFrames)*100;
subplot(1,2,2); plot([0:0.05:1], thr_success, 'r*-'); title('Success Plot: % of frames with overlap ratio >= threshold'); xlabel('Threshold'); ylabel('Percentage of frames');