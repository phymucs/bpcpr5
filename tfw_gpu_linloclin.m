classdef tfw_gpu_linloclin < tfw_i
  %tfw_gpu_linloclin A regressor: local linear + Relu + Dropout + linear
  %   Detailed explanation goes here
  
  properties
  end
  
  methods
    function ob = tfw_gpu_linloclin(mask_, sz1, sz2)
      %%% set the connection structure: a triangular connection
      f = 0.01;
      % 1. linear with mask
      tfs{1}        = tf_conv_mask(mask_);
      tfs{1}.p(1).a = gpuArray( f*randn(sz1, 'single') );
      tfs{1}.p(2).a = gpuArray( zeros(1,sz1(end), 'single') );
      % 2. ReLu
      tfs{2}   = tf_relu();
      tfs{2}.i = tfs{1}.o;
      % 3. Dropout
      tfs{3}   = tf_dropout();
      tfs{3}.i = tfs{2}.o;
      % 4. linear
      tfs{4}        = tf_conv();
      tfs{4}.p(1).a = gpuArray( f*randn(sz2, 'single') );
      tfs{4}.p(2).a = gpuArray( zeros(1,sz2(end), 'single') );
      % write back
      ob.tfs = tfs;
      
      %%% input&output data
      ob.i = n_data(); % X the feature
      ob.o = n_data(); % pout the prediction
      
      %%% set the parameters
      ob.p = dag_util.collect_params( ob.tfs );
    end % tfw_rpd_reg
    
    function ob = fprop(ob)
       %%% Outer Input --> Internal Input
       ob.tfs{1}.i.a = ob.i.a; 
       
       %%% fprop for all
       for i = 1 : numel( ob.tfs )
         ob.tfs{i} = fprop(ob.tfs{i});
         wait(gpuDevice);
       end
       
       %%% Internal Output --> Outer Output: set the loss
       ob.o.a = ob.tfs{end}.o.a;      
    end % fprop
    
    function ob = bprop(ob)
      %%% Outer output --> Internal output
      ob.tfs{end}.o.d = ob.o.d;
      
      %%% bprop for all
      for i = numel(ob.tfs) : -1 : 1
        ob.tfs{i} = bprop(ob.tfs{i});
        wait(gpuDevice);
      end
      
      %%% Internal Input --> Outer Input: unnecessary here      
      ob.i(1).d = ob.tfs{1}.i.d;
      ob.i(2).d = ob.tfs{2}.i(2).d;
    end % bprop
    
  end % methods
  
end

