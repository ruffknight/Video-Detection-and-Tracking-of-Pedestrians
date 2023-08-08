close all, clear all

continuar = true;

menu= {'Deteção de pedestres, labels e trajetórias (dinâmicas e totais)', 'Heatmap', 'Optical flow do movimento dos pedestres', 'Regiões detetadas vs ground truth e success plot', 'Sair do programa'};

while continuar == true
    for i=1:length(menu)
        fprintf('%d%s%s\n', i, ' - ', menu{i})
    end
    
    option = input('Escolha uma das opções: ');
    
    switch option
        case 1
            detection
        case 2
            heatmap
        case 3
            fprintf('%s\n%s\n\n', 'Podemos colecionar alguns centróides de modo a estimar um vetor que nos dará informações sobre a direção, trajetória e velocidade por exemplo, tendo em conta que a footage se trata de câmera fixa.', 'Desta forma podemos criar estimativas de onde se irá encontrar um objeto numa dada frame, desde que a sua trajetória não sofra mudança de direção. V=centroide_atual-centroide_anterior/intervalo de tempo (de uma frame para outra por exemplo)');
        case 4
            bbox_gt_plot
        case 5
            continuar = false;
    end
    
end