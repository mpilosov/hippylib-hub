FROM quay.io/fenicsproject/stable:2017.2.0.r3
MAINTAINER U. Villa

USER root

RUN apt-get update && \
    apt-get install -yy pwgen npm nodejs-legacy python3-pip && \
    npm install -g configurable-http-proxy && \
    pip3 install jupyter notebook && \
    pip3 install jupyterhub && \
    pip3 install jupyterlab
    pip3 install ipywidgets
    jupyter nbextension install --py widgetsnbextension
    jupyter nbextension enable --sys-prefix --py widgetsnbextension
    jupyter labextension install @jupyterlab/hub-extension
    
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN mkdir /etc/certs
#RUN touch /etc/certs/ssl.key
#RUN touch /etc/certs/ssl.crt
#RUN openssl req -x509 -nodes -days 730 -newkey rsa:2048 \
#                 -subj "/C=XY/ST=XYZ/L=XYZ/O=XYZ/CN=example.com" \
#                 -keyout /etc/certs/ssl.key -out /etc/certs/ssl.crt

USER fenics

# Install MUQ
RUN cd /home/fenics && \
    mkdir Installations; mkdir Installations/MUQ_INSTALL && \
    git clone --depth 1 https://mparno@bitbucket.org/mituq/muq2.git && \
    cd muq2/; mkdir build; cd build;  \
    cmake -DCMAKE_INSTALL_PREFIX=/home/fenics/Installations/MUQ_INSTALL -DMUQ_USE_PYTHON=ON ../ && \
    make install
    
# Install hIPPYlib
RUN cd /home/fenics/Installations && \
    git clone https://github.com/hippylib/hippylib.git && \
    chmod -R o+rx hippylib

# Install ConsistentBayes
RUN cd /home/fenics/Installations && \
    git clone https://github.com/mpilosov/consistentbayes.git && \
    chmod -R o+rx ConsistentBayes
    
# Copy the notebooks
RUN cd /home/fenics/Installations && \
    git clone https://github.com/g2s3-2018/labs.git
    
COPY python3_config.json /usr/local/share/jupyter/kernels/python3/kernel.json
ENV LD_LIBRARY_PATH /home/fenics/Installations/MUQ_INSTALL/lib:/home/fenics/Installations/MUQ_INSTALL/muq_external/lib
ENV PYTHONPATH /home/fenics/Installations/MUQ_INSTALL/lib
ENV PYTHONPATH /home/fenics/Installations/hippylib

USER root

COPY jupyterhub_config.py /home/fenics/jupyterhub_config.py
COPY make-users-std-password.sh /etc/my_init.d/make-users-std-password.sh
RUN chmod +x /etc/my_init.d/make-users-std-password.sh
RUN rm /etc/my_init.d/set-home-permissions.sh
COPY update_lab.sh /home/fenics/update_lab.sh
RUN chmod +x /home/fenics/update_lab.sh
RUN mkdir -p /home/fenics/.jupyter
COPY jupyter_notebook_config.py /home/fenics/.jupyter/jupyter_notebook_config.py


ENV NUMBER_OF_USERS 10
WORKDIR /home/fenics/
ENTRYPOINT ["/sbin/my_init","--"]
CMD ["jupyter labhub"]
