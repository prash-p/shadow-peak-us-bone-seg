function US_out = connBone(US, bone_n)

%%% Do connected component analysis
US3 = single(zeros(size(US)));
CC = bwconncomp(US);
numPixels = cellfun(@numel,CC.PixelIdxList);
[sorted, sortedidx] = sort(numPixels, 'descend');

switch nargin
    case 1
        %%%Automatically calculate number of disconnected bone surfaces
        bone_n = (nnz(sorted./sum(sorted) > 0.01));
        sortedidx = sortedidx(1:bone_n);
        for i = 1:length(sortedidx)
            US3(CC.PixelIdxList{sortedidx(i)}) = 1;
        end
        US_out = US3.*US;
      
    case 2
        %%%Number of bone surfaces provided, because known (e.g. in ddh)
        sortedidx = sortedidx(1:bone_n);
        for i = 1:length(sortedidx)
            US3(CC.PixelIdxList{sortedidx(i)}) = 1;
        end
        US_out = US3.*US;
end