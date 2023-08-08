close all, clear all

continuar = true;

menu= {'Dete��o de pedestres, labels e trajet�rias (din�micas e totais)', 'Heatmap', 'Optical flow do movimento dos pedestres', 'Regi�es detetadas vs ground truth e success plot', 'Sair do programa'};

while continuar == true
    for i=1:length(menu)
        fprintf('%d%s%s\n', i, ' - ', menu{i})
    end
    
    option = input('Escolha uma das op��es: ');
    
    switch option
        case 1
            detection
        case 2
            heatmap
        case 3
            fprintf('%s\n%s\n\n', 'Podemos colecionar alguns centr�ides de modo a estimar um vetor que nos dar� informa��es sobre a dire��o, trajet�ria e velocidade por exemplo, tendo em conta que a footage se trata de c�mera fixa.', 'Desta forma podemos criar estimativas de onde se ir� encontrar um objeto numa dada frame, desde que a sua trajet�ria n�o sofra mudan�a de dire��o. V=centroide_atual-centroide_anterior/intervalo de tempo (de uma frame para outra por exemplo)');
        case 4
            bbox_gt_plot
        case 5
            continuar = false;
    end
    
end