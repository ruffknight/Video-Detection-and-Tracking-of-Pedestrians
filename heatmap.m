close all

path = 'View_001/';

nFrames = size(dir([path '/*.jpg']), 1); %dir da-nos uma lista com os nomes de todas as frames .jpg e o size da-nos o numero de frames

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
imgMap = zeros(size(imgbk,1), size(imgbk,2)); %imagem onde vamos 'desenhar' o heatmap

thr = 75;
minArea = 200;

se = strel('disk', 3);

for i=0:(nFrames-1) % ler frames sequencialmente e para cada imagem calcular a diferença com a imagem de background 
    
    strFrame = sprintf('%s%s%.4d.%s', path, 'frame_', i, 'jpg');
    imgfr = imread(strFrame); %para ir buscar cada imagem
    subplot(1,2,1); imshow(imgfr); title('Pedestrians'); hold on;
    
    % ------------- regioes detetadas por nós para esta frame ------------- %
    imgdif = (abs(double(imgbk(:,:,1))-double(imgfr(:,:,1))) > thr) | (abs(double(imgbk(:,:,2))-double(imgfr(:,:,2))) > thr) | (abs(double(imgbk(:,:,3))-double(imgfr(:,:,3))) > thr);
    % imgdif só fica ativo (a 1) no sítio das onde há movimento aka onde há
    % diferenças

    bw = imclose(imgdif, se); %aplicar operação morfológica para limpara as regiões um bocadinho melhor
    % mesmo assim acusa muitas regiões ativas que são ruído - regionprops:
    
    [lb num] = bwlabel(bw);
    regionProps = regionprops(lb, 'Area', 'BoundingBox', 'FilledImage', 'Centroid');
    inds = find([regionProps.Area] > minArea); % guarda os indices das regiões que satisfazem a condição
    
    % --------------------------------------------------------------------- %
    
    
    % ----------------------------- heatmap ------------------------------- %
    for k=1:length(inds) % vamos iterar sobre todas as regioes para podermos desenha-las no heatmap
        [lin col] = find(lb == inds(k)); % devolve todas as posições [y x] da região em questao
        for pos=1:length([lin col])
            imgMap(lin(pos), col(pos)) = imgMap(lin(pos), col(pos)) + 1; % incrementar, no heatmap, as posicoes da regiao em questao
        end
        
    end
    
    if rem(i,10) == 0 % para atualizar o heatmap apenas de 10 em 10 frames
        v_min = min(imgMap(:));
        v_max = max(imgMap(:));

        subplot(1,2,2); imshow(imgMap); title('Heatmap'); hold on
        colormap(jet); colorbar; hold on
        caxis([v_min v_max]); %v_min e v_max para normalizar o colormap

    end
    
    drawnow
    
end

